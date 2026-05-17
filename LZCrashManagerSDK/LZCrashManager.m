//
//  LZCrashManager.m
//  LZCrashManagerSDK
//

#import "LZCrashManager.h"

#import <signal.h>

#import "LZCrashManagerConfiguration.h"
#import "LZCrashReport.h"
#import "LZCrashStore.h"
#import "LZCrashUploader.h"

static NSUncaughtExceptionHandler *LZPreviousExceptionHandler = NULL;
static volatile sig_atomic_t LZHasCapturedCrash = 0;
static NSString *const LZCrashStoreFolderName = @"com.lz.crashmanager.reports";
static void LZHandleUncaughtException(NSException *exception);
static void LZSignalHandler(int signalNumber);
static void LZInstallSignalHandlers(void);

@interface LZCrashManager ()
@property (nonatomic, copy, readwrite, nullable) LZCrashManagerConfiguration *configuration;
@property (nonatomic, strong) LZCrashStore *store;
@property (nonatomic, strong) LZCrashUploader *uploader;
@property (nonatomic, strong) dispatch_queue_t workQueue;
@end

@implementation LZCrashManager

+ (instancetype)sharedManager {
    static LZCrashManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[LZCrashManager alloc] initPrivate];
    });
    return manager;
}

- (instancetype)init {
    [NSException raise:NSInternalInconsistencyException format:@"Use +sharedManager"];
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        NSURL *cachesDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject];
        NSURL *storeDirectoryURL = [cachesDirectory URLByAppendingPathComponent:LZCrashStoreFolderName isDirectory:YES];
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfiguration.timeoutIntervalForRequest = 15.0;
        _store = [[LZCrashStore alloc] initWithDirectoryURL:storeDirectoryURL];
        _uploader = [[LZCrashUploader alloc] initWithSession:[NSURLSession sessionWithConfiguration:sessionConfiguration]];
        _workQueue = dispatch_queue_create("com.lz.crashmanager.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)startWithConfiguration:(LZCrashManagerConfiguration *)configuration {
    self.configuration = [configuration copy];
    [self installHandlers];
    [self.store trimToMaximumCount:self.configuration.maxStoredCrashReportCount];
    [self flushPendingCrashReportsWithCompletion:nil];
}

- (void)flushPendingCrashReportsWithCompletion:(void (^ _Nullable)(NSArray<LZCrashReport *> *uploadedReports, NSArray<NSError *> *errors))completion {
    LZCrashManagerConfiguration *configuration = self.configuration;
    if (!configuration) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"com.lz.crashmanager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Crash manager has not been started."}];
            completion(@[], @[error]);
        }
        return;
    }

    NSArray<LZCrashReport *> *reports = [self.store allCrashReports];
    if (reports.count == 0) {
        if (completion) {
            completion(@[], @[]);
        }
        return;
    }

    dispatch_group_t group = dispatch_group_create();
    NSMutableArray<LZCrashReport *> *uploadedReports = [NSMutableArray array];
    NSMutableArray<NSError *> *errors = [NSMutableArray array];

    for (LZCrashReport *report in reports) {
        dispatch_group_enter(group);
        [self.uploader uploadCrashReport:report configuration:configuration completion:^(NSError * _Nullable error) {
            dispatch_async(self.workQueue, ^{
                if (error) {
                    [errors addObject:error];
                    if ([self.delegate respondsToSelector:@selector(crashManagerDidFailToUploadReport:error:)]) {
                        [self.delegate crashManagerDidFailToUploadReport:report error:error];
                    }
                } else {
                    [uploadedReports addObject:report];
                    [self.store removeCrashReport:report error:nil];
                    if ([self.delegate respondsToSelector:@selector(crashManagerDidUploadReport:)]) {
                        [self.delegate crashManagerDidUploadReport:report];
                    }
                }
                dispatch_group_leave(group);
            });
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            completion([uploadedReports copy], [errors copy]);
        }
    });
}

- (void)installHandlers {
    LZPreviousExceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&LZHandleUncaughtException);

    if (self.configuration.isSignalHandlingEnabled) {
        LZInstallSignalHandlers();
    }
}

- (void)handleCapturedException:(NSException *)exception {
    if (!self.configuration || LZHasCapturedCrash) {
        return;
    }

    LZHasCapturedCrash = 1;
    NSDictionary<NSString *, id> *reportDictionary = [self crashDictionaryForException:exception];
    NSError *error = nil;
    LZCrashReport *report = [self.store persistCrashDictionary:reportDictionary error:&error];
    if (report && [self.delegate respondsToSelector:@selector(crashManagerDidPersistReport:)]) {
        [self.delegate crashManagerDidPersistReport:report];
    }

    if (self.configuration.crashThreadKeepAliveDuration > 0) {
        [self keepCurrentThreadAliveForDuration:self.configuration.crashThreadKeepAliveDuration];
    }

    if (LZPreviousExceptionHandler) {
        LZPreviousExceptionHandler(exception);
    }
}

- (void)handleCapturedSignal:(int)signalNumber {
    if (!self.configuration || LZHasCapturedCrash) {
        return;
    }

    LZHasCapturedCrash = 1;
    NSString *signalReason = [NSString stringWithFormat:@"Signal %d was raised.", signalNumber];
    NSDictionary<NSString *, id> *reportDictionary = @{
        @"identifier": NSUUID.UUID.UUIDString,
        @"incident_type": @"signal",
        @"reason": signalReason,
        @"crashed_thread_name": [NSThread currentThread].name ?: @"",
        @"call_stack_symbols": [NSThread callStackSymbols] ?: @[],
        @"timestamp": @([[NSDate date] timeIntervalSince1970]),
        @"metadata": [self baseMetadata]
    };
    [self.store persistCrashDictionary:reportDictionary error:nil];
}

- (NSDictionary<NSString *, id> *)crashDictionaryForException:(NSException *)exception {
    return @{
        @"identifier": NSUUID.UUID.UUIDString,
        @"incident_type": @"exception",
        @"reason": exception.reason ?: @"Unknown exception",
        @"crashed_thread_name": [NSThread currentThread].name ?: @"",
        @"call_stack_symbols": exception.callStackSymbols ?: @[],
        @"timestamp": @([[NSDate date] timeIntervalSince1970]),
        @"metadata": [self baseMetadata]
    };
}

- (NSDictionary<NSString *, id> *)baseMetadata {
    NSMutableDictionary<NSString *, id> *metadata = [NSMutableDictionary dictionary];
    metadata[@"bundle_identifier"] = [NSBundle mainBundle].bundleIdentifier ?: @"";
    metadata[@"process_name"] = [NSProcessInfo processInfo].processName ?: @"";
    metadata[@"system_version"] = [NSProcessInfo processInfo].operatingSystemVersionString ?: @"";

    if ([self.delegate respondsToSelector:@selector(crashManagerAdditionalMetadata)]) {
        NSDictionary<NSString *, id> *extraMetadata = [self.delegate crashManagerAdditionalMetadata];
        if (extraMetadata.count > 0) {
            [metadata addEntriesFromDictionary:extraMetadata];
        }
    }

    return [metadata copy];
}

- (void)keepCurrentThreadAliveForDuration:(NSTimeInterval)duration {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:duration];
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    while ([[NSDate date] compare:deadline] == NSOrderedAscending) {
        @autoreleasepool {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, false);
        }
    }
    CFRunLoopStop(runLoop);
}

@end

static void LZHandleUncaughtException(NSException *exception) {
    [[LZCrashManager sharedManager] handleCapturedException:exception];
}

static void LZSignalHandler(int signalNumber) {
    [[LZCrashManager sharedManager] handleCapturedSignal:signalNumber];
    signal(signalNumber, SIG_DFL);
    raise(signalNumber);
}

static void LZInstallSignalHandlers(void) {
    signal(SIGABRT, LZSignalHandler);
    signal(SIGILL, LZSignalHandler);
    signal(SIGSEGV, LZSignalHandler);
    signal(SIGFPE, LZSignalHandler);
    signal(SIGBUS, LZSignalHandler);
    signal(SIGPIPE, LZSignalHandler);
}
