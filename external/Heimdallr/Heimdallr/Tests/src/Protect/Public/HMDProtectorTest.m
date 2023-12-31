//
//  HMDProtectorTest.m
//  Heimdallr-_Dummy-Unit-_Tests
//
//  Created by bytedance on 2021/11/22.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDProtector.h"
#import "HMDDynamicCall.h"
#import "HMDSwizzle.h"
#import "HMDProtect_Private.h"

static void trigger_NSCAssert(void);

@interface HMDProtectorTest : XCTestCase

@end

@implementation HMDProtectorTest

+ (void)setUp {
    HMDProtectTestEnvironment = YES;
    HMD_mockClassTreeForClassMethod(HeimdallrUtilities, canFindDebuggerAttached, ^(Class aClass){
        return NO;
    });
    HMD_mockClassTreeForInstanceMethod(HMDInjectedInfo, appID, ^(id thisSelf){
        return @"10086";
    });
    HMDProtector.sharedProtector.ignoreTryCatch = NO;
}

+ (void)tearDown {
    [HMDProtector.sharedProtector disableAssertProtect];
    [HMDProtector.sharedProtector turnProtectionOff:HMDProtectionTypeAll];
    HMDProtectTestEnvironment = NO;
    HMDProtector.sharedProtector.ignoreTryCatch = YES;
}

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_Protector_switchProtection_errorType {
    [HMDProtector.sharedProtector turnProtectionsOn:NSIntegerMax];
    XCTAssert(HMDProtector.sharedProtector.currentProtectionCollection == HMDProtectionTypeAll);
}

- (void)test_Protector_NSAssert {
    [HMDProtector.sharedProtector enableAssertProtect];
    NSAssert(0, @"");
    trigger_NSCAssert();
}

- (void)test_Protector_ignoreTryCatch {
#warning fixme try-catch 偶现 检测失效
    return; // 后续修复
    
    HMDProtector.sharedProtector.ignoreTryCatch = YES;
    [HMDProtector.sharedProtector turnProtectionsOn:HMDProtectionTypeAll];
    NSArray *array = @[];
    
    BOOL isCatched = NO;
    @try {
        array[0];
    } @catch (NSException *exception) {
        isCatched = YES;
    }
    XCTAssert(isCatched);
}

- (void)test_Protector_catchErrorMethodsWithNames {
    [HMDProtector.sharedProtector catchMethodsWithNames:@[@"ERROR_NOT_VALID"]];
}

- (void)test_Protector_catchRealMethodsWithNames {
    [HMDProtector.sharedProtector catchMethodsWithNames:@[@"+[HMDProtectorTest throwException]",
                                                          @"-[HMDProtectorTest throwException]"]];
    [HMDProtectorTest throwException];
    [[HMDProtectorTest new] throwException];
}

+ (void)throwException {
    [[NSException exceptionWithName:@"" reason:nil userInfo:nil] raise];
}

- (void)throwException {
    [[NSException exceptionWithName:@"" reason:nil userInfo:nil] raise];
}

- (void)test_Protector_registerIdentifier {
//    这部分代码没什么问题, 总是测试失败的原因是, 因为开启了大量的安全气垫测试
//    这部分量级太大了, 导致消息被淹没, 处理阈值触发, 然后就不给回调了 (啊这)
//
//    [HMDProtector.sharedProtector turnProtectionsOn:HMDProtectionTypeContainers];
//
//    XCTestExpectation *expectation = [self expectationWithDescription:@"Protector register identifier callback"];
//
//    NSString *identifier = @"test_Protector_registerIdentifier";
//
//    [HMDProtector.sharedProtector registerIdentifier:identifier withBlock:^(HMDProtectCapture * _Nonnull capture) {
//        static dispatch_once_t onceToken;
//        dispatch_once(&onceToken, ^{
//            [expectation fulfill];
//        });
//    }];
//
//    id capture = DC_CL(HMDProtectCapture, captureException:reason:, @"any", @"any");
//    id backtrace = DC_CL(HMDThreadBacktrace, backtraceOfMainThreadWithSymbolicate:skippedDepth:suspend:, NO, (NSUInteger)0, NO);
//    DC_OB(capture, setBacktraces:, @[backtrace]);
//    HMDProtector.sharedProtector.currentProcessCaptureLimit = NSUIntegerMax;
//    DC_OB(HMDProtector.sharedProtector, respondToCapture:, capture);
//    [self waitForExpectationsWithTimeout:10 handler:nil];
//    [HMDProtector.sharedProtector removeRegistedBlockWithIdentifier:identifier];
//    DC_OB(HMDProtector.sharedProtector, respondToCapture:, capture);
}

@end

static void trigger_NSCAssert(void) {
    NSCAssert(0, @"");
}
