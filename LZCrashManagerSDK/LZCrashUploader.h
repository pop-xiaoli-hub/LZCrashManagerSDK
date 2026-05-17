//
//  LZCrashUploader.h
//  LZCrashManagerSDK
//

#import <Foundation/Foundation.h>

@class LZCrashManagerConfiguration;
@class LZCrashReport;

NS_ASSUME_NONNULL_BEGIN

@interface LZCrashUploader : NSObject

- (instancetype)initWithSession:(NSURLSession *)session;
- (void)uploadCrashReport:(LZCrashReport *)report
            configuration:(LZCrashManagerConfiguration *)configuration
               completion:(void (^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
