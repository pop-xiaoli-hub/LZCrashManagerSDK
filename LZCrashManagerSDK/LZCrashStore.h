//
//  LZCrashStore.h
//  LZCrashManagerSDK
//

#import <Foundation/Foundation.h>

@class LZCrashReport;

NS_ASSUME_NONNULL_BEGIN

@interface LZCrashStore : NSObject

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL;
- (nullable LZCrashReport *)persistCrashDictionary:(NSDictionary<NSString *, id> *)crashDictionary error:(NSError **)error;
- (NSArray<LZCrashReport *> *)allCrashReports;
- (BOOL)removeCrashReport:(LZCrashReport *)report error:(NSError **)error;
- (void)trimToMaximumCount:(NSUInteger)maximumCount;

@end

NS_ASSUME_NONNULL_END
