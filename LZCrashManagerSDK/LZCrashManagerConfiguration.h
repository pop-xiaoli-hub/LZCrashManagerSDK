//
//  LZCrashManagerConfiguration.h
//  LZCrashManagerSDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCrashManagerConfiguration : NSObject <NSCopying>

@property (nonatomic, copy) NSURL *uploadURL;
@property (nonatomic, copy) NSString *appIdentifier;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *HTTPHeaders;
@property (nonatomic, copy) NSDictionary<NSString *, id> *customParameters;
@property (nonatomic, assign) NSTimeInterval crashThreadKeepAliveDuration;
@property (nonatomic, assign) NSUInteger maxStoredCrashReportCount;
@property (nonatomic, assign, getter=isSignalHandlingEnabled) BOOL signalHandlingEnabled;
@property (nonatomic, assign, getter=isDebugLogEnabled) BOOL debugLogEnabled;

+ (instancetype)configurationWithUploadURL:(NSURL *)uploadURL
                             appIdentifier:(NSString *)appIdentifier
                                appVersion:(NSString *)appVersion;

@end

NS_ASSUME_NONNULL_END
