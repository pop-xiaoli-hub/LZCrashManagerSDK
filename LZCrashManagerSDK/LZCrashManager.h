//
//  LZCrashManager.h
//  LZCrashManagerSDK
//

#import <Foundation/Foundation.h>

@class LZCrashManagerConfiguration;
@class LZCrashReport;

NS_ASSUME_NONNULL_BEGIN

@protocol LZCrashManagerDelegate <NSObject>
@optional
- (NSDictionary<NSString *, id> *)crashManagerAdditionalMetadata;
- (void)crashManagerDidPersistReport:(LZCrashReport *)report;
- (void)crashManagerDidUploadReport:(LZCrashReport *)report;
- (void)crashManagerDidFailToUploadReport:(LZCrashReport *)report error:(NSError *)error;
@end

@interface LZCrashManager : NSObject

@property (class, nonatomic, readonly) LZCrashManager *sharedManager;
@property (nonatomic, weak, nullable) id<LZCrashManagerDelegate> delegate;
@property (nonatomic, copy, readonly, nullable) LZCrashManagerConfiguration *configuration;

- (void)startWithConfiguration:(LZCrashManagerConfiguration *)configuration;
- (void)flushPendingCrashReportsWithCompletion:(void (^ _Nullable)(NSArray<LZCrashReport *> *uploadedReports,
                                                                   NSArray<NSError *> *errors))completion;

@end

NS_ASSUME_NONNULL_END
