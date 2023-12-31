//
//  TestOhayooHeader.m
//  RangersAppLog-Unit-Tests
//
//  Created by 朱元清 on 2021/1/22.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrack.h>
#import <RangersAppLog/BDAutoTrack+Private.h>
#import <RangersAppLog/BDAutoTrack+OhayooGameTrack.h>
#import <RangersAppLog/BDAutoTrackLocalConfigService.h>

@interface TestOhayooHeader : XCTestCase

@property (nonatomic, strong) BDAutoTrack *track;

@property (nonatomic, weak) BDAutoTrackLocalConfigService *localConfigService;

@end

@implementation TestOhayooHeader

- (void)setUp {
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:@"159486" launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test2";
    self.track = [BDAutoTrack trackWithConfig:config];
    [NSThread sleepForTimeInterval:0.1];
    self.localConfigService = bd_settingsServiceForAppID(config.appID);
    
    [self.localConfigService clearCustomHeader];
}

- (void)tearDown {
    [self.localConfigService clearCustomHeader];
}

- (NSDictionary *)customDic {
    return [self.localConfigService performSelector:@selector(customData)];
}

- (void)testOhayooHeaderStringValue {
    XCTAssertNotNil([self customDic]);
    NSString *vPackageChannel = @"test_packagechanel";
    XCTAssertNil([[self customDic] objectForKey:OhayooCustomHeaderKeyPackageChannel]);
    
    [self.track ohayooHeaderSetObject:vPackageChannel forKey:OhayooCustomHeaderKeyPackageChannel];
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertTrue([[[self customDic] objectForKey:OhayooCustomHeaderKeyPackageChannel] isEqualToString:vPackageChannel]);
    
    [self.track removeCustomHeaderValueForKey:OhayooCustomHeaderKeyPackageChannel];
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertNil([[self customDic] objectForKey:OhayooCustomHeaderKeyPackageChannel]);
}

- (void)testOhayooHeaderIntValue {
    XCTAssertNotNil([self customDic]);
    NSNumber *vUserType = @(100);
    XCTAssertNil([[self customDic] objectForKey:OhayooCustomHeaderKeyUserType]);
    
    [self.track ohayooHeaderSetObject:vUserType forKey:OhayooCustomHeaderKeyUserType];
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertTrue([[[self customDic] objectForKey:OhayooCustomHeaderKeyUserType] isEqualToNumber:vUserType]);
    
    [self.track removeCustomHeaderValueForKey:OhayooCustomHeaderKeyUserType];
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertNil([[self customDic] objectForKey:OhayooCustomHeaderKeyUserType]);
}

/**
 测试 Value 类型不匹配的情况
 SDK应该不处理此情况，即不会做运行时类型检查。只管上报。
 */
- (void)testOhayooHeaderValueTypeNoRuntimeCheck {
    XCTAssertNotNil([self customDic]);
    NSString *vUserType = @"I should not be a string, but SDK will set and send me anyway. No runtime typecheck is performed at runtime. ";
    XCTAssertNil([[self customDic] objectForKey:OhayooCustomHeaderKeyUserType]);
    
    [self.track ohayooHeaderSetObject:vUserType forKey:OhayooCustomHeaderKeyUserType];
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertTrue([[[self customDic] objectForKey:OhayooCustomHeaderKeyUserType] isEqualToString:vUserType]);
    
    [self.track removeCustomHeaderValueForKey:OhayooCustomHeaderKeyUserType];
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertNil([[self customDic] objectForKey:OhayooCustomHeaderKeyUserType]);
}

@end
