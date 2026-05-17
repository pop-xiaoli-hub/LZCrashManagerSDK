//
//  LZCrashUploader.m
//  LZCrashManagerSDK
//

#import "LZCrashUploader.h"

#import "LZCrashManagerConfiguration.h"
#import "LZCrashReport.h"

@interface LZCrashUploader ()
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation LZCrashUploader

- (instancetype)initWithSession:(NSURLSession *)session {
    self = [super init];
    if (self) {
        _session = session;
    }
    return self;
}

- (void)uploadCrashReport:(LZCrashReport *)report
            configuration:(LZCrashManagerConfiguration *)configuration
               completion:(void (^)(NSError * _Nullable error))completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:configuration.uploadURL];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [configuration.HTTPHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [request setValue:value forHTTPHeaderField:key];
    }];

    NSMutableDictionary<NSString *, id> *payload = [[report dictionaryRepresentation] mutableCopy];
    payload[@"app_identifier"] = configuration.appIdentifier ?: @"";
    payload[@"app_version"] = configuration.appVersion ?: @"";
    [payload addEntriesFromDictionary:configuration.customParameters ?: @{}];

    NSError *serializationError = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&serializationError];
    if (!bodyData) {
        completion(serializationError);
        return;
    }

    request.HTTPBody = bodyData;
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(__unused NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            completion(error);
            return;
        }

        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (statusCode < 200 || statusCode >= 300) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Crash report upload failed with status code %ld", (long)statusCode]
            };
            completion([NSError errorWithDomain:@"com.lz.crashmanager.upload" code:statusCode userInfo:userInfo]);
            return;
        }

        completion(nil);
    }];
    [task resume];
}

@end
