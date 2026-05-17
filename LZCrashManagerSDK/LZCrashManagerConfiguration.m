//
//  LZCrashManagerConfiguration.m
//  LZCrashManagerSDK
//

#import "LZCrashManagerConfiguration.h"

@implementation LZCrashManagerConfiguration

+ (instancetype)configurationWithUploadURL:(NSURL *)uploadURL
                             appIdentifier:(NSString *)appIdentifier
                                appVersion:(NSString *)appVersion {
    LZCrashManagerConfiguration *configuration = [[self alloc] init];
    configuration.uploadURL = uploadURL;
    configuration.appIdentifier = appIdentifier;
    configuration.appVersion = appVersion;
    return configuration;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _HTTPHeaders = @{};
        _customParameters = @{};
        _crashThreadKeepAliveDuration = 3.0;
        _maxStoredCrashReportCount = 10;
        _signalHandlingEnabled = NO;
        _debugLogEnabled = NO;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LZCrashManagerConfiguration *copy = [[[self class] allocWithZone:zone] init];
    copy.uploadURL = self.uploadURL;
    copy.appIdentifier = self.appIdentifier;
    copy.appVersion = self.appVersion;
    copy.HTTPHeaders = self.HTTPHeaders;
    copy.customParameters = self.customParameters;
    copy.crashThreadKeepAliveDuration = self.crashThreadKeepAliveDuration;
    copy.maxStoredCrashReportCount = self.maxStoredCrashReportCount;
    copy.signalHandlingEnabled = self.signalHandlingEnabled;
    copy.debugLogEnabled = self.debugLogEnabled;
    return copy;
}

@end
