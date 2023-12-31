//
//  EMAAppLinkModel.m
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/10/21.
//

#import "EMAAppLinkModel.h"
#import <OPFoundation/NSURLComponents+EMA.h>
#import <OPFoundation/BDPUtils.h>
#import "EMAAppEngine.h"
#import <OPFoundation/EMAFeatureGating.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>

static NSString * const kAppLinkOpenPath = @"/client/mini_program/open";
NSString * const kAppLink_appId = @"appId";
NSString * const kAppLink_path = @"path";
NSString * const kAppLink_path_android = @"path_android";
NSString * const kAppLink_path_ios = @"path_ios";
NSString * const kAppLink_path_ipad = @"path_ipad";
NSString * const kAppLink_path_pc = @"path_pc";
NSString * const kAppLink_mode = @"mode";
NSString * const kAppLink_min_lk_ver = @"min_lk_ver";
NSString * const kAppLink_min_lk_ver_android = @"min_lk_ver_android";
NSString * const kAppLink_min_lk_ver_ios = @"min_lk_ver_ios";
NSString * const kAppLink_min_lk_ver_ipad = @"min_lk_ver_ipad";
NSString * const kAppLink_min_lk_ver_pc = @"min_lk_ver_pc";
NSString * const kAppLink_oversea_host = @"applink.larksuite.com";
NSString * const kAppLink_host = @"applink.feishu.cn";
NSString * const kAppLink_op_tracking = @"op_tracking";

@interface EMAAppLinkModel ()

@property (nonatomic, strong) NSURLComponents *urlComponents;

@end

@implementation EMAAppLinkModel

- (instancetype)initWithType:(EMAAppLinkType)type
{
    if (self = [super init]) {
        _type = type;
        NSURLComponents *urlCom = [[NSURLComponents alloc] initWithString:@"https://"];
        // 服务端为ka配置了不同的applink的domain，但实际不支持自定义domain的applink, 具体现象可以参见ka的这个bughttps://jira.bytedance.com/browse/SUITE-667387
        // 此处添加一个fg，使用线上applink配置domain的，走自定义applink的domain，
        // 否则参照Android和pc的做法，写死分享的applink domain
        // fg是为了方便后续按需从服务端配置上进行修改后，支持自定义applink domain，目前fg为关，需要自定义的时候打开即可，https://fg.bytedance.net/?ticket=ST-1566530582-ruFPGrnGFluKUM5fPQAM7XNO3xaEagIU#/key/detail/microapp.applink.custom.domain
        if([EMAFeatureGating boolValueForKey:EMAFeatureGatingKeyMicroAppAppLinkCustomDomain]) {
            urlCom.host = [EMAAppEngine.currentEngine.config.domainConfig appLinkDomain];
        } else {
            NSArray *appLinkDomains = [AppLinkOCBadge domainCurrentSetting];
            if ([appLinkDomains isKindOfClass:[NSArray class]] && appLinkDomains.count > 0) {
                urlCom.host = [appLinkDomains firstObject];
            }
        }
        urlCom.path = [self getPath];
        _urlComponents = urlCom;
    }

    return self;
}

- (EMAAppLinkModel * (^)(NSString *key, NSString *value))addQuery;
{
    return ^id(NSString *key, NSString *value){
        if (!BDPIsEmptyString(key) && !BDPIsEmptyString(value)) {
            [self.urlComponents setQueryItemWithKey:key value:value];
        }
        return self;
    };
}

- (NSURL *)generateURL
{
    return self.urlComponents.URL;
}

- (NSString *)getPath
{
    switch (self.type) {
        case EMAAppLinkTypeOpen:
            return kAppLinkOpenPath;
            break;
    }

    return kAppLinkOpenPath;
}

@end

