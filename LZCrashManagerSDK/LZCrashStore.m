//
//  LZCrashStore.m
//  LZCrashManagerSDK
//

#import "LZCrashStore.h"

#import "LZCrashReport.h"

@interface LZCrashStore ()
@property (nonatomic, copy) NSURL *directoryURL;
@end

@implementation LZCrashStore

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL {
    self = [super init];
    if (self) {
        _directoryURL = [directoryURL copy];
        [self ensureDirectoryExists];
    }
    return self;
}

- (nullable LZCrashReport *)persistCrashDictionary:(NSDictionary<NSString *, id> *)crashDictionary error:(NSError **)error {
    NSMutableDictionary<NSString *, id> *mutableDictionary = [crashDictionary mutableCopy];
    NSString *identifier = mutableDictionary[@"identifier"];
    if (identifier.length == 0) {
        identifier = NSUUID.UUID.UUIDString;
        mutableDictionary[@"identifier"] = identifier;
    }

    NSURL *fileURL = [self.directoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", identifier]];
    NSData *data = [NSJSONSerialization dataWithJSONObject:mutableDictionary options:0 error:error];
    if (!data) {
        return nil;
    }

    if (![data writeToURL:fileURL options:NSDataWritingAtomic error:error]) {
        return nil;
    }

    return [[LZCrashReport alloc] initWithDictionary:mutableDictionary];
}

- (NSArray<LZCrashReport *> *)allCrashReports {
    NSArray<NSURL *> *fileURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.directoryURL includingPropertiesForKeys:@[NSURLCreationDateKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    NSMutableArray<LZCrashReport *> *reports = [NSMutableArray array];
    for (NSURL *fileURL in fileURLs) {
        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        if (data.length == 0) {
            continue;
        }
        NSDictionary<NSString *, id> *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![dictionary isKindOfClass:NSDictionary.class]) {
            continue;
        }
        [reports addObject:[[LZCrashReport alloc] initWithDictionary:dictionary]];
    }

    [reports sortUsingComparator:^NSComparisonResult(LZCrashReport *left, LZCrashReport *right) {
        return [left.timestamp compare:right.timestamp];
    }];
    return [reports copy];
}

- (BOOL)removeCrashReport:(LZCrashReport *)report error:(NSError **)error {
    NSURL *fileURL = [self.directoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", report.identifier]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        return YES;
    }
    return [[NSFileManager defaultManager] removeItemAtURL:fileURL error:error];
}

- (void)trimToMaximumCount:(NSUInteger)maximumCount {
    NSArray<LZCrashReport *> *reports = [self allCrashReports];
    if (reports.count <= maximumCount) {
        return;
    }

    NSUInteger overflow = reports.count - maximumCount;
    for (NSUInteger index = 0; index < overflow; index++) {
        [self removeCrashReport:reports[index] error:nil];
    }
}

- (void)ensureDirectoryExists {
    [[NSFileManager defaultManager] createDirectoryAtURL:self.directoryURL withIntermediateDirectories:YES attributes:nil error:nil];
}

@end
