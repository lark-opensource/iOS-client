//
//  CJPayWebViewOfflineWrapper.m
//  Pods
//
//  Created by 易培淮 on 2021/5/6.
//

#import "CJPayWebViewOfflineWrapper.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "CJPayProtocolManager.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPaySDKMacro.h"

@interface CJPayWebViewOfflineWrapper()<CJPayOfflineService>

@property (nonatomic, copy) NSString *appId;

@end

@implementation CJPayWebViewOfflineWrapper

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(shared), CJPayOfflineService)
})

+ (instancetype)shared {
    static CJPayWebViewOfflineWrapper *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CJPayWebViewOfflineWrapper alloc] init];
    });
    return instance;
}

- (void)p_registerOffline {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayGurdService) i_enableGurdOfflineAfterSettings];
}

- (void)i_registerOffline:(NSString *)appid {
    self.appId = appid;
    if ([CJPaySettingsManager shared].remoteSettings && [CJPaySettingsManager shared].remoteSettings.gurdFalconModel) {
        [self p_registerOffline];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_registerOffline) name:CJPayFetchSettingsSuccessNotification object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
