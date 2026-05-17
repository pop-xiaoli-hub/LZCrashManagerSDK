//
//  LZCrashReport.h
//  LZCrashManagerSDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCrashReport : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *incidentType;
@property (nonatomic, copy, readonly) NSString *reason;
@property (nonatomic, copy, readonly) NSString *crashedThreadName;
@property (nonatomic, copy, readonly) NSArray<NSString *> *callStackSymbols;
@property (nonatomic, copy, readonly) NSDate *timestamp;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *metadata;

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dictionary;
- (NSDictionary<NSString *, id> *)dictionaryRepresentation;

@end

NS_ASSUME_NONNULL_END
