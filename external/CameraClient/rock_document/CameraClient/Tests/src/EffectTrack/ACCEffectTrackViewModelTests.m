//
//  ACCEffectTrackViewModelTests.m
//  CameraClient-Pods-AwemeTests-Unit-_Tests
//
//  Created by Chipengliu on 2020/12/17.
//

#import <XCTest/XCTest.h>
#import <CameraClient/ACCEffectTrackViewModel.h>
#import <CameraClient/AWEVideoFragmentInfo.h>

@interface ACCEffectTrackViewModelTests : XCTestCase

@end

@implementation ACCEffectTrackViewModelTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

/// 测试埋点数据和片段关联逻辑
- (void)testAddEffectParamsForFragment {
    ACCEffectTrackViewModel *viewModel = [[ACCEffectTrackViewModel alloc] init];
    AWEVideoFragmentInfo *fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
    [viewModel addFragment:fragment];
    [viewModel updateEffectTrackModelWithParams:@{@"key" : @"value"} type:ACCTrackMessageTypeRecord];
    NSString *res = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:@[fragment] filter:nil];
    XCTAssertTrue([res isEqualToString:@"key:value"]);
}

/// 测试开拍后能否带上开拍前effect上报的埋点
- (void)testTrackBeforeRecordStart {
    ACCEffectTrackViewModel *viewModel = [[ACCEffectTrackViewModel alloc] init];
    // effectSDK 开拍前上报
    [viewModel updateEffectTrackModelWithParams:@{@"key_before" : @"value_before"} type:ACCTrackMessageTypeRecord];
    // 开拍后添加 fragment
    AWEVideoFragmentInfo *fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
    [viewModel addFragment:fragment];
    NSString *res = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:@[fragment] filter:nil];
    XCTAssertTrue([res isEqualToString:@"key_before:value_before"]);
    
    // 结束拍摄前，继续上报
    [viewModel updateEffectTrackModelWithParams:@{@"key_after" : @"value_after"} type:ACCTrackMessageTypeRecord];
    res = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:@[fragment] filter:nil];
    XCTAssertTrue([res isEqualToString:@"key_before:value_before,key_after:value_after"]);
}

/// 测试暂停拍摄之后埋点数据是否正常
- (void)testClearFragment {
    ACCEffectTrackViewModel *viewModel = [[ACCEffectTrackViewModel alloc] init];
    AWEVideoFragmentInfo *fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
    [viewModel addFragment:fragment];
    [viewModel updateEffectTrackModelWithParams:@{@"key_before" : @"value_before"} type:ACCTrackMessageTypeRecord];
    
    // 模拟停止拍摄，effect 继续发消息给到客户端
    [viewModel clearTrackParamsCache];
    [viewModel updateEffectTrackModelWithParams:@{@"key_after" : @"value_after"} type:ACCTrackMessageTypeRecord];
    
    // 校验拍摄结束前数据
    NSString *res = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:@[fragment] filter:nil];
    XCTAssertTrue([res isEqualToString:@"key_before:value_before"]);
    
    // 校验新开拍的一段视频埋点数据
    fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
    [viewModel addFragment:fragment];
    res = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:@[fragment] filter:nil];
    XCTAssertTrue([res isEqualToString:@"key_after:value_after"]);
}

/// 测试多段拍场景
- (void)testMultiFragment {
    ACCEffectTrackViewModel *viewModel = [[ACCEffectTrackViewModel alloc] init];
    
    // 第一段
    AWEVideoFragmentInfo *fragment0 = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
    [viewModel addFragment:fragment0];
    [viewModel updateEffectTrackModelWithParams:@{@"fragment_0_key" : @"fragment_0_value"} type:ACCTrackMessageTypeRecord];
    
    // 暂停会，effect继续上报，这些数据作为下载一段视频的埋点数据
    [viewModel clearTrackParamsCache];
    [viewModel updateEffectTrackModelWithParams:@{@"fragment_1_key_before" : @"fragment_0_value_before"} type:ACCTrackMessageTypeRecord];
    // 开拍第二段视频
    AWEVideoFragmentInfo *fragment1 = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
    [viewModel addFragment:fragment1];
    // 拍摄过程中，effect持续上报数据
    [viewModel updateEffectTrackModelWithParams:@{@"fragment_1_key_after" : @"fragment_0_value_after"} type:ACCTrackMessageTypeRecord];
    NSString *res = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:@[fragment0, fragment1] filter:nil];
    XCTAssertTrue([res isEqualToString:@"fragment_0_key:fragment_0_value;fragment_1_key_before:fragment_0_value_before,fragment_1_key_after:fragment_0_value_after"]);
}

@end
