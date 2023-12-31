//
//  CJPayBridgePlugin_sendDeviceInfo.m
//  Pods
//
//  Created by 易培淮 on 2021/9/13.
//

#import "CJPayBridgePlugin_sendDeviceInfo.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "NSDictionary+CJPay.h"
#import "CJPayMetaSecManager.h"
#import "CJPaySDKMacro.h"
#import "CJPayPrivateServiceHeader.h"

@interface CJPayMetaSecPageCallback : NSObject

@property (nonatomic, strong) NSMutableArray *pageStack;
@property (nonatomic, assign) NSInteger currentPage;

@end

@implementation CJPayMetaSecPageCallback

- (NSMutableArray *)pageStack {
    if (!_pageStack) {
        _pageStack = [NSMutableArray array];
    }
    return _pageStack;
}

- (int)getScenePageName {
    return _currentPage;
}

@end

static CJPayMetaSecPageCallback *_metaSecPageCallback = nil;

@implementation CJPayBridgePlugin_sendDeviceInfo

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_sendDeviceInfo, sendDeviceInfo),
                            @"ttcjpay.sendDeviceInfo");
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_sendDeviceInfo, setDeviceInfo),
                            @"ttcjpay.setDeviceInfo");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}


- (void)sendDeviceInfoWithParam:(NSDictionary *)param
                       callback:(TTBridgeCallback)callback
                         engine:(id<TTBridgeEngine>)engine
                     controller:(UIViewController *)controller
{
    NSString *scene = [param cj_stringValueForKey:@"scene"];
    
    if (!([scene isKindOfClass:NSString.class] && [scene length] > 0)) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"scene参数错误")
        return;
    }
    if ([CJPayMetaSecManager defaultService].delegate) {
        [[CJPayMetaSecManager defaultService] reportForScene:scene];
        TTBRIDGE_CALLBACK_SUCCESS
    } else {
        TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"安全SDK代理未设置")
    }
}

- (void)setDeviceInfoWithParam:(NSDictionary *)param
                      callback:(TTBridgeCallback)callback
                        engine:(id<TTBridgeEngine>)engine
                    controller:(UIViewController *)controller {
    NSNumber *page = [param btd_numberValueForKey:@"page"];
    NSString *action = [param cj_stringValueForKey:@"action"];
    
    if (![page isKindOfClass:NSNumber.class] || !Check_ValidString(action)) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"page或者action参数错误")
        return;
    }
    // app处于非活跃状态，不上报
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    if ([action isEqualToString:@"push"]) {
        // 避免重复push
        if ([[self.metaSecPageCallback.pageStack lastObject] integerValue] != [page integerValue]) {
            [self.metaSecPageCallback.pageStack addObject:page];
        }
        [CJ_OBJECT_WITH_PROTOCOL(CJPaySecService) enterScene:[page stringValue]];
    } else if ([action isEqualToString:@"pop"]) {
        [self.metaSecPageCallback.pageStack.copy enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSNumber *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.integerValue == page.integerValue) {
                [self.metaSecPageCallback.pageStack removeObjectAtIndex:idx];
                *stop = YES;
            }
        }];
        [CJ_OBJECT_WITH_PROTOCOL(CJPaySecService) leaveScene:[page stringValue]];
    }
    if ([CJPayMetaSecManager defaultService].delegate) {
        page = [self.metaSecPageCallback.pageStack lastObject];
        TTBRIDGE_CALLBACK_SUCCESS
    } else {
        TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"安全SDK代理未设置")
    }
}

- (CJPayMetaSecPageCallback *)metaSecPageCallback {
    if (!_metaSecPageCallback) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _metaSecPageCallback = [CJPayMetaSecPageCallback new];
            if ([CJPayMetaSecManager defaultService].delegate) {
                [[CJPayMetaSecManager defaultService] registerScenePageNameCallback:1 cb:_metaSecPageCallback];
            }
        });
    }
    return _metaSecPageCallback;
}

@end
