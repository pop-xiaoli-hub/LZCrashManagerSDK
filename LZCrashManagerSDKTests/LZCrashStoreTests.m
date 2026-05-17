//
//  LZCrashStoreTests.m
//  LZCrashManagerSDKTests
//

#import <XCTest/XCTest.h>

#import <LZCrashManagerSDK/LZCrashReport.h>

#import "../LZCrashManagerSDK/LZCrashStore.h"

@interface LZCrashStoreTests : XCTestCase
@property (nonatomic, copy) NSURL *directoryURL;//创建一个临时目录用于测试
@property (nonatomic, strong) LZCrashStore *store;
@end

@implementation LZCrashStoreTests

- (void)setUp {
    [super setUp];
    NSString *directoryName = [NSString stringWithFormat:@"LZCrashStoreTests-%@", NSUUID.UUID.UUIDString];
    self.directoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:directoryName] isDirectory:YES];
    self.store = [[LZCrashStore alloc] initWithDirectoryURL:self.directoryURL];
}

//XCTest的生命周期方法，每一个test方法执行结束之后都会执行teardown清理测试环境
- (void)tearDown {
    [[NSFileManager defaultManager] removeItemAtURL:self.directoryURL error:nil];
    self.store = nil;
    self.directoryURL = nil;
    [super tearDown];
}

- (void)testPersistedCrashReportCanBeLoaded {
  //先构造一个崩溃信息字典并转换成报告对象
    NSDictionary<NSString *, id> *dictionary = @{
        @"identifier": @"report-1",
        @"incident_type": @"exception",
        @"reason": @"unit-test",
        @"crashed_thread_name": @"main",
        @"call_stack_symbols": @[@"frame1", @"frame2"],
        @"timestamp": @(100),
        @"metadata": @{@"foo": @"bar"}
    };

    NSError *error = nil;
    LZCrashReport *persistedReport = [self.store persistCrashDictionary:dictionary error:&error];

    XCTAssertNil(error);
    XCTAssertEqualObjects(persistedReport.identifier, @"report-1");
    NSArray<LZCrashReport *> *reports = [self.store allCrashReports];
    XCTAssertEqual(reports.count, 1);
    XCTAssertEqualObjects(reports.firstObject.reason, @"unit-test");
}

- (void)testTrimRemovesOldestReports {
    for (NSUInteger index = 0; index < 3; index++) {
        NSDictionary<NSString *, id> *dictionary = @{
            @"identifier": [NSString stringWithFormat:@"report-%lu", (unsigned long)index],
            @"incident_type": @"exception",
            @"reason": @"trim",
            @"crashed_thread_name": @"main",
            @"call_stack_symbols": @[],
            @"timestamp": @(100 + index),
            @"metadata": @{}
        };
        [self.store persistCrashDictionary:dictionary error:nil];
    }

    [self.store trimToMaximumCount:2];

    NSArray<LZCrashReport *> *reports = [self.store allCrashReports];
    XCTAssertEqual(reports.count, 2);
    XCTAssertEqualObjects(reports.firstObject.identifier, @"report-1");
    XCTAssertEqualObjects(reports.lastObject.identifier, @"report-2");
}

@end
