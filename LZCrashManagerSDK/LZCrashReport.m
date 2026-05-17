//
//  LZCrashReport.m
//  LZCrashManagerSDK
//

#import "LZCrashReport.h"

static NSString *const LZCrashReportTimestampKey = @"timestamp";

@interface LZCrashReport ()
@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, copy, readwrite) NSString *incidentType;
@property (nonatomic, copy, readwrite) NSString *reason;
@property (nonatomic, copy, readwrite) NSString *crashedThreadName;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *callStackSymbols;
@property (nonatomic, copy, readwrite) NSDate *timestamp;
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, id> *metadata;
@end

@implementation LZCrashReport

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dictionary {
    self = [super init];
    if (self) {
        _identifier = [dictionary[@"identifier"] ?: NSUUID.UUID.UUIDString copy];
        _incidentType = [dictionary[@"incident_type"] ?: @"unknown" copy];
        _reason = [dictionary[@"reason"] ?: @"" copy];
        _crashedThreadName = [dictionary[@"crashed_thread_name"] ?: @"" copy];
        _callStackSymbols = [dictionary[@"call_stack_symbols"] isKindOfClass:NSArray.class] ? [dictionary[@"call_stack_symbols"] copy] : @[];
        _metadata = [dictionary[@"metadata"] isKindOfClass:NSDictionary.class] ? [dictionary[@"metadata"] copy] : @{};

        id rawTimestamp = dictionary[LZCrashReportTimestampKey];
        if ([rawTimestamp isKindOfClass:NSString.class]) {
            _timestamp = [NSDate dateWithTimeIntervalSince1970:[(NSString *)rawTimestamp doubleValue]];
        } else if ([rawTimestamp isKindOfClass:NSNumber.class]) {
            _timestamp = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)rawTimestamp doubleValue]];
        } else {
            _timestamp = [NSDate date];
        }
    }
    return self;
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    return @{
        @"identifier": self.identifier ?: @"",
        @"incident_type": self.incidentType ?: @"",
        @"reason": self.reason ?: @"",
        @"crashed_thread_name": self.crashedThreadName ?: @"",
        @"call_stack_symbols": self.callStackSymbols ?: @[],
        @"metadata": self.metadata ?: @{},
        LZCrashReportTimestampKey: @([self.timestamp timeIntervalSince1970])
    };
}

@end
