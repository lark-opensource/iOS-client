//
//  CJPaySecManager.m
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/5/22.
//

#import "CJPaySecManager.h"
#import "CJPaySafeUtil.h"
#import "CJPayFeatureCollectorManager.h"
#import "CJPayCommonUtil.h"
#import "CJPaySDKMacro.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayCallFeatureCollector.h"
#import "CJPayCaptureFeatureCollector.h"
#import "CJPaySettingsManager.h"

NSString * const kRiskControlKeyPath = @"cjpay_security_risk_control.risk_control_parameter_upload_enabled";
@interface CJPaySecManager()<CJPaySecService>
 
@property (nonatomic, strong) CJPayFeatureCollectorManager *manager;
@property (nonatomic, assign) BOOL settingIsOpen;

@end

@implementation CJPaySecManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassToPtocol(self, CJPaySecService);
})

- (void)start {
    self.settingIsOpen = [CJPaySettingsManager boolValueForKeyPath:kRiskControlKeyPath];
    if (self.settingIsOpen) {
        [self.manager registerCollector:[CJPayCallFeatureCollector new]];
        [self.manager registerCollector:[CJPayCaptureFeatureCollector new]];
    }
}

- (void)enterScene:(NSString *)scene {
    [self.manager enterScene:scene];
}

- (void)leaveScene:(NSString *)scene {
    [self.manager leaveScene:scene];
}

- (NSDictionary *)buildSafeInfo:(NSDictionary *)info context:(NSDictionary *)context{
    NSTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSDictionary *result = [self.manager buildFeaturesParams];
//  结构定义技术方案文档https://bytedance.feishu.cn/wiki/HaG4wp4Dbi1MVjkEAvfc7n8Xn8f
    id<CJPayEngimaProtocol> engine = [CJPaySafeManager buildEngimaEngine:@"sec" useCert:@"MFowFAYIKoEcz1UBgi0GCCqBHM9VAYItA0IABORuB//K5fgO9cKcWO+W6sM7QxjBGyvc2g33G5HWW+BMwWxWNjb1qe0z9tDUJJKbpKqYlLlWgU+V5aWEt00vF4I="];
    NSString *encryptResult = [CJPaySafeUtil objEncryptField:[CJPayCommonUtil dictionaryToJson:result] engimaEngine:engine];
    NSString *channel = [UIApplication btd_currentChannel];
    BOOL isInhouse = [channel isEqualToString:@"test"] || [channel isEqualToString:@"local_test"];

    NSMutableDictionary *mutableResultDic = [@{
        @"finance_risk": @{
            @"data": CJString(encryptResult),
            @"compress_type": @"", // 压缩方案
            @"encrypt_type": [CJPaySafeManager secureInfoVersion], // 加解密方案
            @"version_code": @"0.1", // 版本号
        }
    } mutableCopy];
    if (isInhouse) {
        [mutableResultDic addEntriesFromDictionary:@{@"original_data": result ?: @{}}];
    }
    NSTimeInterval calTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[mutableResultDic copy]];
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionaryWithDictionary:@{@"type": @"upload_data", @"cal_time": @(calTime), @"data_size": @(data.length / 1000)}];
    [trackParams addEntriesFromDictionary:context];
    [CJMonitor trackService:@"wallet_rd_sec_message" extra:[trackParams copy]]; // 主要计算接口的耗时
    return [mutableResultDic copy];
}

- (CJPayFeatureCollectorManager *)manager {
    if (!_manager && self.settingIsOpen) { // 如果settings没打开，这里直接不返回manager，因为manager里面会有初始化和启动的工作
        _manager = [CJPayFeatureCollectorManager new];
    }
    return _manager;
}

@end
