//
//  CJPayAIEnginePluginImpl.m
//  Aweme
//
//  Created by ByteDance on 2023/5/31.
//

#import "CJPayAIEnginePluginImpl.h"
#import <Pitaya/Pitaya.h>
#import "NSDictionary+CJPay.h"
#import "CJPayAIEnginePlugin.h"
#import "CJPaySDKMacro.h"

static CJPayAIEnginePluginImpl *_instance = nil;
@interface CJPayAIEnginePluginImpl()<CJPayAIEnginePlugin>
@property (nonatomic, strong) NSMutableDictionary *outputs;
@end

@implementation CJPayAIEnginePluginImpl

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(shareInstance), CJPayAIEnginePlugin)
});

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (void)setup {
    if (![[Pitaya sharedInstance] isReady]) {
        return;
    }
    [[Pitaya sharedInstance] registerAppLogRunEventCallback:CAIJING_RISK_SDK_FEATURE callback:^(BOOL success, NSError * _Nullable error, PTYTaskData * _Nullable output, PTYPackage * _Nullable package) {
        if (success && output.params) {
            // 响应算法包返回的output数据
            [self.outpusts setObject:output.params forKey:CAIJING_RISK_SDK_FEATURE];
        }
    }];
}

- (NSDictionary *)getOutputForBusiness:(NSString *)business {
    if (!business) {
        return nil;
    }
    NSDictionary *output = [self.outputs cj_objectForKey:business];
    // 取到后清除
    [self.outputs removeObjectForKey:business];
    return output;
}

- (NSMutableDictionary *)outpusts {
    if (!_outputs) {
        _outputs = [NSMutableDictionary dictionary];
    }
    return _outputs;
}

@end
