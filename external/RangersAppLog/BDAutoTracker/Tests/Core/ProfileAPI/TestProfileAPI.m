//
//  TestProfileAPI.m
//  BDAutoTracker_Tests
//
//  Created by 朱元清 on 2020/9/14.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "RangersAppLog.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackRegisterService.h"

// 手动声明BDProfileEntry
@interface BDProfileEntry : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *valueHash;
@property (nonatomic) NSTimeInterval timeSince1970;

+ (NSString *)calcValueHash:(NSObject *)value;
@end

// 声明Profile category的部分接口，用于单元测试
@interface BDAutoTrack (Profile)

- (NSMutableDictionary *)validateProfileDict:(NSDictionary *)profileDict;

- (BOOL)impl_profileSet:(NSDictionary *)profileDict;

- (BOOL)impl_profileSetOnce:(NSDictionary *)profileDict;

- (BOOL)impl_profileUnset:(NSString *)profileName;

- (BOOL)impl_profileIncrement:(NSDictionary *)profileDict;

- (BOOL)impl_profileAppend:(NSDictionary *)profileDict;

// 用于set流控
- (NSMutableDictionary *)profileEntriesForSSID:(NSString *)ssid;

// 用于setOnce流控
- (NSMutableSet *)profileNamesForSSID:(NSString *)ssid;

- (void)_resetProfileFlowControlPolicy;
@end


/// profile API test case
@interface TestProfileAPI : XCTestCase

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *ssID;
@property (atomic, strong) BDAutoTrack *track;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@end


@implementation TestProfileAPI
- (void)onRegisterSuccess:(NSNotification *)not  {
    dispatch_semaphore_signal(self.semaphore);
}

- (BDProfileEntry *)set_ObjectForKey:(NSString *)key {
    return [[self.track profileEntriesForSSID:self.ssID] objectForKey:key];
}

- (BOOL)setOnce_containsKey:(NSString *)key {
    return [[self.track profileNamesForSSID:self.ssID] containsObject:key] == YES;
}


/// 保证每次运行testcase前都是不同的BDAutoTrack实例
- (void)setUp {
    self.semaphore = dispatch_semaphore_create(0);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRegisterSuccess:)
                                                 name:BDAutoTrackNotificationRegisterSuccess
                                               object:nil];
    
    self.appID = @"0";
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:self.appID launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test_profile";
    config.appID = self.appID;
    config.serviceVendor = BDAutoTrackServiceVendorCN;
    self.track = [BDAutoTrack trackWithConfig:config];
    [self.track startTrack];
    
    // 等待注册服务初始化完成。
    dispatch_semaphore_wait(self.semaphore, 3 * NSEC_PER_SEC);
    
    // 设置一个假的SSID
    NSDictionary *mockRegisterResponse = @{
        @"bd_did": @"688",
        @"cd": @"688",
        @"install_id_str": @"688",
        @"new_user": @(0),
        @"ssid": @"0",
        @"server_time": @(1600673743),
        @"device_id": @(0),
        @"install_id": @(6889691)
    };
    
    // 休眠0.2秒，等待注册服务初始化完成。
    usleep(200000);
    
    BDAutoTrackRegisterService *registerService = bd_registerServiceForAppID(self.appID);
    [registerService updateParametersWithResponse:mockRegisterResponse];
    self.ssID = registerService.ssID;
    [self.track _resetProfileFlowControlPolicy];
}

- (void)tearDown {
    [BDAutoTrackServiceCenter.defaultCenter unregisterAllServices];
    self.track = nil;
}

- (void)testProfileUnitTestMetas {
    XCTAssertNotNil(self.appID);
    XCTAssertNotNil(self.ssID);
    XCTAssertNotNil(bd_registerServiceForAppID(self.appID));
}


- (void)testDoNotReportEmptyData {
    XCTAssertFalse([self.track impl_profileSet:@{}]);
    XCTAssertFalse([self.track impl_profileSetOnce:@{}]);
}

#pragma mark 类型检查
// 值的合法类型：字符串、整型、浮点型、字符串数组类型
// 测试非法类型

- (void)testInvalidValueType_noStrangeType {
    NSDictionary *invalidProfileDict = @{@"user_level": NSData.data};
    XCTAssertFalse([self.track impl_profileSet:invalidProfileDict]);
    XCTAssertFalse([self.track impl_profileSetOnce:invalidProfileDict]);
}

- (void)testInvalidValueType_noIntInArray {
    NSDictionary *invalidProfileDict = @{@"interests": @[@"Reading", @(1)]};
    XCTAssertFalse([self.track impl_profileSet:invalidProfileDict]);
    XCTAssertFalse([self.track impl_profileSetOnce:invalidProfileDict]);
}

- (void)testInvalidValueType_onlyStringInArray {
    NSDictionary *invalidProfileDict = @{@"interests": @[@"Reading", NSData.data]};
    XCTAssertFalse([self.track impl_profileSet:invalidProfileDict]);
    XCTAssertFalse([self.track impl_profileSetOnce:invalidProfileDict]);
}

- (void)testInvalidValueType_canAppendString {
    NSDictionary *profileDict = @{@"interests": @[@"Reading"]};
    XCTAssertTrue([self.track impl_profileSet:profileDict]);
    
    // Can Append a String
    XCTAssertTrue([self.track impl_profileAppend:@{@"interests": @"Hang out"}]);
}

- (void)testInvalidValueType_canAppendStringArray {
    NSDictionary *profileDict = @{@"interests": @[@"Reading"]};
    XCTAssertTrue([self.track impl_profileSet:profileDict]);
    
    // Can Append a String Array
    NSMutableDictionary *appendDict = [NSMutableDictionary new];
    [appendDict setObject:[NSArray arrayWithObjects:@"Hang out", @"Make firends", nil] forKey:@"interests"];
    XCTAssertTrue([self.track impl_profileAppend:appendDict]);

}

- (void)testInvalidValueType_cannotAppendNumber {
    NSDictionary *profileDict = @{@"interests": @[@"Reading"]};
    XCTAssertTrue([self.track impl_profileSet:profileDict]);
    
    // Should Not Append a number
    XCTAssertFalse([self.track impl_profileAppend:@{@"interests": @(100)}]);
    XCTAssertFalse([self.track impl_profileAppend:@{@"interests": @(100.1)}]);
}

- (void)testInvalidValueType_canOnlyIncrementInterger {
    // 可以increment一个整数
    XCTAssertTrue([self.track impl_profileSet:@{@"user_level": @(-10)}]);
    XCTAssertTrue([self.track impl_profileSet:@{@"user_level": @(0)}]);
    XCTAssertTrue([self.track impl_profileSet:@{@"user_level": @(10)}]);
    
    // Should Not Increment a String
    XCTAssertFalse([self.track impl_profileIncrement:@{@"user_level": @"1"}]);
    
    // Should Not Increment a List
    XCTAssertFalse([self.track impl_profileIncrement:@{@"user_level": @[@(1)]}]);
    
    // Should Not Increment a float number
    XCTAssertFalse([self.track impl_profileIncrement:@{@"user_level": @(3.14)}]);
    XCTAssertFalse([self.track impl_profileIncrement:@{@"user_level": @(0.5)}]);
}


// 测试合法类型
- (void)testValidValueType {
    NSDictionary *legalProfileDict = @{@"user_level": @(100),
                                       @"interests": @[@"跑团", @"爬山", @"看书"]};
    XCTAssertTrue([self.track impl_profileSet:legalProfileDict]);
    XCTAssertTrue([self.track impl_profileSetOnce:legalProfileDict]);
    
    XCTAssertTrue([self.track impl_profileUnset:@"user_level"]);
}

- (void)testValidValueType_2 {
    NSDictionary *legalProfileDict = @{@"user_level": @(3.1415926535),
                                       @"interests": @[@"跑团", @"爬山", @"看书"]};
    XCTAssertTrue([self.track impl_profileSet:legalProfileDict]);
    XCTAssertTrue([self.track impl_profileSetOnce:legalProfileDict]);
    
    XCTAssertTrue([self.track impl_profileUnset:@"user_level"]);
}

#pragma mark - 功能测试

/// set, unset, set
- (void)testSetAfterUnset {
    BDProfileEntry *storedEntry;
    XCTAssertTrue([self.track impl_profileSet:@{@"user_level": @(10)}]);
    storedEntry = [self set_ObjectForKey:@"user_level"];
    XCTAssertTrue([[BDProfileEntry calcValueHash:@(10)] isEqualToString:storedEntry.valueHash]);
    
    XCTAssertTrue([self.track impl_profileUnset:@"user_level"]);
    storedEntry = [self set_ObjectForKey:@"user_level"];
    XCTAssertNil(storedEntry);
    
    XCTAssertTrue([self.track impl_profileSet:@{@"user_level": @(10)}]);
    storedEntry = [self set_ObjectForKey:@"user_level"];
    XCTAssertTrue([[BDProfileEntry calcValueHash:@(10)] isEqualToString:storedEntry.valueHash]);
    
    XCTAssertTrue([self.track impl_profileUnset:@"user_level"]);
    storedEntry = [self set_ObjectForKey:@"user_level"];
    XCTAssertNil(storedEntry);
}

/// setOnce, unset, setOnce
- (void)testSetOnceAfterUnset {
    XCTAssertTrue([self.track impl_profileSetOnce:@{@"user_level": @(10)}]);
    XCTAssertTrue([self setOnce_containsKey:@"user_level"]);
    
    XCTAssertTrue([self.track impl_profileUnset:@"user_level"]);
    XCTAssertFalse([self setOnce_containsKey:@"user_level"]);
    
    XCTAssertTrue([self.track impl_profileSetOnce:@{@"user_level": @(10)}]);
    XCTAssertTrue([self setOnce_containsKey:@"user_level"]);
    
    XCTAssertTrue([self.track impl_profileUnset:@"user_level"]);
    XCTAssertFalse([self setOnce_containsKey:@"user_level"]);
}


- (void)testIncrement {
    BDProfileEntry *storedEntry;
    int base = 10;
    XCTAssertTrue([self.track impl_profileSet:@{@"user_level": @(base)}]);
    storedEntry = [self set_ObjectForKey:@"user_level"];
    XCTAssertTrue([[BDProfileEntry calcValueHash:@(base)] isEqualToString:storedEntry.valueHash]);
    
    int offset = 2333;
    XCTAssertTrue([self.track impl_profileIncrement:@{@"user_level": @(offset)}]);
    storedEntry = [self set_ObjectForKey:@"user_level"];
    // increment接口仅做上报，不会增加SDK内部维护的数据结构哈。所以storedEntry中依然是10
    XCTAssertEqualObjects([BDProfileEntry calcValueHash:@(base)], storedEntry.valueHash);
    
    // 不支持increment浮点数
    XCTAssertFalse([self.track impl_profileIncrement:@{@"user_level": @(0.5)}]);
    
    offset = -2333;
    // increment一个负数也是可以的
    XCTAssertTrue([self.track impl_profileIncrement:@{@"user_level": @(offset)}]);
}

- (void)testAppend {
    BDProfileEntry *storedEntry;
    NSDictionary *profileDict = @{@"interests": @[@"跑团", @"爬山", @"看书"]};
    
    // Set
    XCTAssertTrue([self.track impl_profileSet:profileDict]);
    storedEntry = [self set_ObjectForKey:@"interests"];
    XCTAssertEqualObjects([BDProfileEntry calcValueHash:profileDict[@"interests"]], storedEntry.valueHash);
    
    // Append
    XCTAssertTrue([self.track impl_profileAppend:@{@"interests": @"吃好吃的"}]);
    storedEntry = [self set_ObjectForKey:@"interests"];
    // Append接口仅做上报，不会增加SDK内部维护的数据结构哈。所以storedEntry中内容不变
    XCTAssertEqualObjects([BDProfileEntry calcValueHash:profileDict[@"interests"]], storedEntry.valueHash);
}

#pragma mark - 测试 Flow Control

- (void)testHighSpeedFlowSet {
    XCTAssertTrue([self.track impl_profileSet:@{@"user_level": @(10)}]);
    for (int i = 0; i < 1000; i++) {
        XCTAssertFalse([self.track impl_profileSet:@{@"user_level": @(10)}]);
    }
}

- (void)testHighSpeedFlowSetOnce {
    XCTAssertTrue([self.track impl_profileSetOnce:@{@"user_level": @(10)}]);
    for (int i = 0; i < 1000; i++) {
        XCTAssertFalse([self.track impl_profileSetOnce:@{@"user_level": @(10)}]);
    }
}

@end
