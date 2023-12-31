//
//  CJPayABTestManager.m
//  CJPay-CJPayDemoTools-Example
//
//  Created by 孟源 on 2022/5/16.
//

#import "CJPayABTestNewPluginImpl.h"
#import <BDCommonABTestSDK/BDCommonABTestManager.h>
#import <BDCommonABTestSDK/BDCommonABTestManager+Private.h>
#import <BDCommonABTestSDK/BDCommonABTestManager+Cache.h>
#import <BDCommonABTestSDK/BDCommonABTestExperimentItemModel.h>
#import "CJPaySDKMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPayABTestManager.h"
#import "CJPayRequestParam.h"

@interface CJPayABTestNewPluginImpl() <CJPayRequestParamInjectDataProtocol>
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDCommonABTestBaseExperiment *> *experimentsDic;
@end


@implementation CJPayABTestNewPluginImpl

CJPAY_REGISTER_PLUGIN({
    CJPayRegisterCurrentClassToPtocol(self, CJPayABTestNewPlugin);
    [CJPayRequestParam injectDataProtocol:self];
});

+ (instancetype)defaultService {
    static CJPayABTestNewPluginImpl *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJPayABTestNewPluginImpl new];
    });
    return instance;
}

// 注入财经支付中台请求的参数
BDCommonABSDKExtraInitFunction () {
    NSString *sdkVersion = [CJSDKParamConfig defaultConfig].version;
    [BDCommonABTestManager addExtraParameter:@{@"cjpay_sdk_version" : CJString(sdkVersion)}];
}

#pragma - mark 向基础框架注入数据
+ (NSDictionary *)injectDevInfoData {
    NSString *isDouPayProcess = [[CJPayABTestManager sharedInstance] getABTestValWithKey:CJPayABIsDouPayProcess exposure:NO];
    return @{@"is_sdk_standard" : CJString(isDouPayProcess)};
}

+ (NSDictionary *)injectReskInfoData {
    return @{};
}

- (void)registerABTestWithKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    [self registerABTestWithKey:key defaultValue:defaultValue isSticky:NO];
}

- (void)registerABTestWithKey:(NSString *)key defaultValue:(NSString *)defaultValue isSticky:(BOOL)isSticky {
    BDCommonABTestValueType valueType = BDCommonABTestValueTypeString;
    BDCommonABTestBaseExperiment *experiment = [[BDCommonABTestBaseExperiment alloc]
                                                initWithKey:CJString(key)
                                                owner:nil
                                                description:nil
                                                defaultValue:CJString(defaultValue)
                                                valueType:valueType
                                                isSticky:isSticky
                                                isBind2User:NO
                                                settingsValueBlock:^id(NSString *key) {
        NSDictionary *libraABSettingsDic = [CJPaySettingsManager shared].currentSettings.libraABSettingsDic;
        id settingsValue = [libraABSettingsDic cj_objectForKey:key defaultObj:CJString(defaultValue)];
        return settingsValue;
    }];
    [self.experimentsDic cj_setObject:experiment forKey:CJString(key)];
    [BDCommonABTestManager registerExperiment:experiment];
    [[CJPayABTestManager sharedInstance].libraKeyArray btd_addObject:key];
}

- (NSString *)getABTestValWithKey:(NSString *)key exposure:(BOOL)exposure {
    if (!Check_ValidString(key)) {
        CJPayLogAssert(NO, @"%@为空或者不是string类型", key);
        return nil;
    }
    
    //BDCommonABTest可以实现优先取libra实验值，其次是settings值，最后是默认值
    id abValue = [BDCommonABTestManager getExperimentValueForKey:key withExposure:exposure];
    id experimentVal = [self.experimentsDic cj_objectForKey:CJString(key)];

    BDCommonABTestExperimentItemModel *experimentModel = [[BDCommonABTestManager sharedManager] savedItemForKey:CJString(key)];
    NSString *abSource = @"libra";

    if ([experimentVal isKindOfClass:[BDCommonABTestBaseExperiment class]]) {
        BDCommonABTestBaseExperiment *experiment = (BDCommonABTestBaseExperiment *)experimentVal;
        if ([experiment.source containsString:@"settings"]) {
            abSource = @"settings";
        } else if ([experiment.source containsString:@"default"]) {
            abSource = @"default";
        }
        if (!abValue) {
            abValue = experiment.defaultValue;
            abSource = @"default";
        }
    } else {
        CJPayLogError(@"experimentVal class type wrong, type = %@", NSStringFromClass([experimentVal class]));
    }

    return [self abTestValToString:abValue];
}

- (NSString *)abTestValToString:(id)abValue {
    if ([abValue isKindOfClass:[NSString class]]) {
        return abValue;
    } else if ([abValue isKindOfClass:[NSNumber class]]) {
        return [((NSNumber *)abValue) stringValue];
    } else if ([abValue isKindOfClass:[NSArray class]] || [abValue isKindOfClass:[NSDictionary class]]) {
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:abValue options:kNilOptions error:&error];
        if (!error && jsonData) {
            return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    CJPayLogError(@"传入的数据类型不支持转化为string");
    return nil;
}

#pragma mark - getter & setter
- (NSMutableDictionary<NSString *, BDCommonABTestBaseExperiment *> *)experimentsDic {
    if (!_experimentsDic) {
        _experimentsDic = [NSMutableDictionary new];
    }
    return _experimentsDic;
}



@end
