//
//  ACCEffectTrackTests.m
//  CameraClient-Pods-AwemeTests-Unit-_Tests
//
//  Created by Chipengliu on 2020/12/16.
//

#import <XCTest/XCTest.h>
#import <CameraClient/AWEVideoFragmentInfo.h>
#import <Baymax/BYMAssert.h>

@interface ACCEffectTrackParamsTests : XCTestCase

@end

@implementation ACCEffectTrackParamsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

/// 单段视频端中，逗号分隔字符串是否用按照预期
- (void)testParamsInOneComponent {
    AWEVideoFragmentInfo *fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
    NSArray<ACCEffectTrackParams *> *trackParamsArray = [self effectTrackParamsWithCount:3 fragmentIndex:0 needTrackInEdit:NO needTrackInPublish:NO];
    fragment.effectTrackParams = trackParamsArray;
    NSString *res = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:@[fragment] filter:nil];
    NSUInteger commaCount = [self countOfSubString:@"," string:res];
    
    NSArray<NSString *> *kvStringArray = [res componentsSeparatedByString:@","];
    BYMAssert(kvStringArray.count == commaCount+1, @"comma count is invalid! commaCount=%zi|kvStringArray=%@", commaCount, kvStringArray);
}

/// 多段视频的埋点拼接后，分号分割是否符合预期
- (void)testComponentsCount {
    NSInteger fragmentCount = arc4random() % 10;
    NSMutableArray<AWEVideoFragmentInfo *> *fragmentArray = [NSMutableArray array];
    for (NSInteger i = 0; i < fragmentCount; i++) {
        AWEVideoFragmentInfo *fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
        NSArray<ACCEffectTrackParams *> *trackParamsArray = [self effectTrackParamsWithCount:3 fragmentIndex:i needTrackInEdit:NO needTrackInPublish:NO];
        fragment.effectTrackParams = trackParamsArray.copy;
    
        [fragmentArray addObject:fragment];
    }
    
    NSString *res = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:fragmentArray.copy filter:nil];
    NSArray<NSString *> *components = [res componentsSeparatedByString:@";"];
    BYMAssert(components.count == fragmentCount, @"components is invalid! ans=%zi|res=%zi", fragmentCount, components.count);
}

/// 模拟多段视频，其中某段视频没有埋点
- (void)testOneEmptyParamsInComponents {
    NSInteger fragmentCount = 3;
    NSInteger emptyIndex = arc4random() % fragmentCount;
    NSMutableArray<AWEVideoFragmentInfo *> *fragmentArray = [NSMutableArray array];
    for (NSInteger i = 0; i < fragmentCount; i++) {
        AWEVideoFragmentInfo *fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
        if (emptyIndex != i) {
            fragment.effectTrackParams = [self effectTrackParamsWithCount:2 fragmentIndex:i needTrackInEdit:NO needTrackInPublish:NO];
        }
    
        [fragmentArray addObject:fragment];
    }
    
    NSString *res = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:fragmentArray.copy filter:nil];
    NSArray<NSString *> *components = [res componentsSeparatedByString:@";"];
    for (NSInteger i = 0; i < fragmentCount; i++) {
        if (i == emptyIndex) {
            BYMAssert(components[i].length == 0, @"components is invalid! i=%zi|emptyIndex=%zi|str=%@|res=%@", i, emptyIndex, components[i], res);
        } else {
            BYMAssert(components[i].length > 0, @"components is invalid! i=%zi|emptyIndex=%zi|str=%@|res=%@", i, emptyIndex, components[i], res);
        }
    }
}

/// 测试所有视频片段都没有effect埋点
- (void)testNoParamsInAllFragment {
    NSInteger fragmentCount = 3;
    NSMutableArray<AWEVideoFragmentInfo *> *fragmentArray = [NSMutableArray array];
    for (NSInteger i = 0; i < fragmentCount; i++) {
        AWEVideoFragmentInfo *fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
        NSMutableArray<ACCEffectTrackParams *> *trackParamsArray = [[NSMutableArray alloc] init];
        ACCEffectTrackParams *params = [[ACCEffectTrackParams alloc] init];
        [trackParamsArray addObject:params];
        fragment.effectTrackParams = trackParamsArray.copy;
    
        [fragmentArray addObject:fragment];
    }
    
    NSString *res = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:fragmentArray.copy filter:nil];
    BYMAssert(res.length == 0, @"empty components is invalid! fragmentArray=%@", fragmentArray);
}

- (void)testParamsFilter {
    AWEVideoFragmentInfo *editFragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
    editFragment.effectTrackParams = [self effectTrackParamsWithCount:2 fragmentIndex:0 needTrackInEdit:YES needTrackInPublish:NO];
    NSString *editRes = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:@[editFragment] filter:^BOOL(ACCEffectTrackParams * _Nonnull param) {
        return param.needTrackInEdit;
    }];
    BYMAssert(editRes.length > 0);
    
    NSString *editEmptyRes = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:@[editFragment] filter:^BOOL(ACCEffectTrackParams * _Nonnull param) {
        return param.needTrackInPublish;
    }];
    BYMAssert(editEmptyRes.length == 0);
    
    AWEVideoFragmentInfo *publishFragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
    publishFragment.effectTrackParams = [self effectTrackParamsWithCount:2 fragmentIndex:0 needTrackInEdit:NO needTrackInPublish:YES];
    NSString *publishRes = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:@[publishFragment] filter:^BOOL(ACCEffectTrackParams * _Nonnull param) {
        return param.needTrackInPublish;
    }];
    BYMAssert(publishRes.length > 0);
    
    NSString *publishEmptyRes = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:@[publishFragment] filter:^BOOL(ACCEffectTrackParams * _Nonnull param) {
        return param.needTrackInEdit;
    }];
    BYMAssert(publishEmptyRes.length == 0);
}

- (NSUInteger)countOfSubString:(NSString *)subString string:(NSString *)string {
    NSUInteger count = 0, length = [string length];
    NSRange range = NSMakeRange(0, length);
    while(range.location != NSNotFound)
    {
      range = [string rangeOfString:subString options:0 range:range];
      if(range.location != NSNotFound)
      {
        range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
        count++;
      }
    }
    
    return count;
}

- (NSArray<ACCEffectTrackParams *> *)effectTrackParamsWithCount:(NSInteger)count
                                                  fragmentIndex:(NSUInteger)fragmentIndex
                                                needTrackInEdit:(BOOL)needTrackInEdit
                                             needTrackInPublish:(BOOL)needTrackInPublish
{
    NSMutableArray<ACCEffectTrackParams *> *trackParamsArray = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < count; i++) {
        ACCEffectTrackParams *params = [[ACCEffectTrackParams alloc] init];
        params.needTrackInEdit = needTrackInEdit;
        params.needTrackInPublish = needTrackInPublish;
        params.params = @{
            [NSString stringWithFormat:@"fragment_%zi_field_0", fragmentIndex] : [NSString stringWithFormat:@"fragment_%zi_value_0", fragmentIndex],
            [NSString stringWithFormat:@"fragment_%zi_field_1", fragmentIndex] : [NSString stringWithFormat:@"fragment_%zi_value_0", fragmentIndex],
            [NSString stringWithFormat:@"fragment_%zi_field_2", fragmentIndex] : [NSString stringWithFormat:@"fragment_%zi_value_0", fragmentIndex],
        };
        [trackParamsArray addObject:params];    
    }
    return trackParamsArray;
}

@end
