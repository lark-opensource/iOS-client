//
//  EMANetworkAPI.m
//  EEMicroAppSDK
//
//  Created by houjihu on 2018/12/20.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "EMANetworkAPI.h"
//#import "EMAAppEngine.h"
#import "NSString+EMA.h"
#import "BDPApplicationManager.h"
#import "BDPUtils.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import "EMAAppEngineConfig.h"
#import "BDPTimorClient.h"
#import "BDPMacroUtils.h"
#import "OPResolveDependenceUtil.h"

// 获取在对应环境(比如SAAS,KA)下的业务配置
static NSString *const kEMANetworkAPIPath_getEnvConfig = @"getEnvConfig";

@implementation EMAAPI

/*----------------------------------------------------------*/
#pragma mark                 基础方法
/*----------------------------------------------------------*/

+ (BOOL)isOpenPlatformRequestForURLString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    return [url.host isEqualToString:self.domainConfig.openMinaDomain] || [url.host isEqualToString:self.domainConfig.openDomain];
}

+ (BOOL)needLarkSessionForURLString:(NSString *)urlString {
    return [urlString ema_hasPrefix:self.uploadAppLoadInfo]
    || [urlString ema_hasPrefix:self.uploadAppInstallInfo]
    || [urlString ema_hasPrefix:self.getUpdateAppInfos];
}

+ (EMAAppEngineConfig *)currentAppEngineConfig {
    EMAAppEngineConfig *config = [OPResolveDependenceUtil currentAppEngineConfig];
    return config;
}

+ (MicroAppDomainConfig *)domainConfig {
//    if (EMAAppEngine.currentEngine.config.domainConfig != nil) {
//        return EMAAppEngine.currentEngine.config.domainConfig;
//    }
    EMAAppEngineConfig *engineConfig = [self currentAppEngineConfig];
    if(engineConfig.domainConfig != nil){
        return engineConfig.domainConfig;
    }
    return [MicroAppDomainConfig getDomainWithoutLogin];
}

+ (NSString * _Nullable)urlWithHost:(NSString *)host path:(NSString *)path{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:@"https://"];
    urlComponents.host = host;
    urlComponents.path = path;
    return urlComponents.URL.absoluteString;
}

+ (void)printAllURL {
#ifdef DEBUG
    NSMutableDictionary *allUrl = NSMutableDictionary.dictionary;
//    allUrl[@"envType"] = @(EMAAppEngine.currentEngine.config.envType);
    allUrl[@"envType"] = @([self currentAppEngineConfig].envType);
    allUrl[@"configCenterURL"] = [self configCenterURL];
    allUrl[@"configCenterURL"] = [self configCenterURL];
    allUrl[@"userLoginURL"] = [self userLoginURL];
    allUrl[@"checkSessionURL"] = [self checkSessionURL];
    allUrl[@"appMetaURL"] = [self appMetaURL];
    allUrl[@"batchAppMetaURL"] = [self batchAppMetaURL];
    allUrl[@"cardMetaURLs"] = [self cardMetaUrls].firstObject;
    allUrl[@"userIdURL"] = [self userIdURL];
    allUrl[@"userIdsByOpenIDsURL"] = [self userIdsByOpenIDsURL];
    allUrl[@"chatIdURL"] = [self chatIdURL];
    allUrl[@"openIdURL"] = [self openIdURL];
    allUrl[@"openChatIdsByChatIdsURL"] = [self openChatIdsByChatIdsURL];
    allUrl[@"uploadAuthURL"] = [self uploadAuthURL];
    allUrl[@"hasAuthURL"] = [self hasAuthURL];
    allUrl[@"getUserTicketURL"] = [self getUserTicketURL];
    allUrl[@"authConfirmURL"] = [self authConfirmURL];
    allUrl[@"syncClientAuthURL"] = [self syncClientAuthURL];
    allUrl[@"editorSearchURL"] = [self editorSearchURL];
    allUrl[@"unsupportedContextURL"] = [self unsupportedContextURL];
    allUrl[@"vodFetcherUrl"] = [self vodFetcherUrl:@"token"];
    allUrl[@"addressBaseUrl"] = [self addressBaseUrl];
    allUrl[@"webviewURLNotSupportPage"] = [self webviewURLNotSupportPage];
    allUrl[@"clickProgramReportURL"] = [self clickProgramReportURL];
    allUrl[@"serviceRefererURL"] = [self serviceRefererURL];
    NSString *str = allUrl.JSONRepresentation;
    BDPLogDebug(@"EMAAllURL %@", str);
#endif
}

/*----------------------------------------------------------*/
#pragma mark                 Base
/*----------------------------------------------------------*/

+ (NSString *)baseURLAppendingPath:(NSString *)path {
    NSString *url = [self urlWithHost:self.domainConfig.openMinaDomain
                                 path:@"/open-apis/mina"];

    return [url ema_urlStringByAppendingPathComponent:path];
}

+ (NSString *)baseURLAppendingPathWhenGetAppMeta:(NSString *)path {
    NSString * host = self.domainConfig.openMinaDomain;
    //开关开启，且新域名的配置不为空，则走新的域名key：open_pkm
    if ([OPSDKFeatureGating enableGetAppMetaDomainShift] &&
        !BDPIsEmptyString(self.domainConfig.openPkm)) {
        host = self.domainConfig.openPkm;
    }
    NSString *url = [self urlWithHost:host
                                 path:@"/open-apis/mina"];

    return [url ema_urlStringByAppendingPathComponent:path];
}

+ (NSString *)userLoginURL {
    return [self baseURLAppendingPath:@"v2/login"];
}

+ (NSString *)checkSessionURL {
    return [self baseURLAppendingPath:@"checkSession"];
}

+ (NSString *)userInfoURL {
    return [self baseURLAppendingPath:@"getUserInfo"];
}

+ (NSString *)userInfoH5URL {
    return [self baseURLAppendingPath:@"jssdk/getUserInfo"];
}

+ (NSString *)appMetaURL {
    return [self baseURLAppendingPathWhenGetAppMeta:@"v2/getAppMeta"];
}

+ (NSString *)batchAppMetaURL {
    return [self baseURLAppendingPath:@"mget_app_meta_v2"];
}

/// 卡片meta请求urls数组（目前只有一个元素）
+ (NSArray * _Nonnull)cardMetaUrls {
    return @[[self baseURLAppendingPath:@"v3/getAppMeta/batch"]?:@""];
}

+ (NSString *)userIdURL {
    return [self baseURLAppendingPath:@"v2/getUserIDByOpenID"];
}

+ (NSString *)userIdsByOpenIDsURL {
    return [self baseURLAppendingPath:@"v2/getUserIDsByOpenIDs"];
}

+ (NSString *)chatIdURL {
    return [self baseURLAppendingPath:@"v2/getChatIDByOpenID"];
}

+ (NSString *)chatIdByOpenChatIdURL {
    return [self baseURLAppendingPath:@"getChatIDsByOpenChatIDs"];
}

+ (NSString *)openIdURL {
    return [self baseURLAppendingPath:@"v2/getOpenIDsByUserIDs"];
}

+ (NSString *)contactInfosURL {
    return [self baseURLAppendingPath:@"v4/getOpenUserSummary"];
}

+ (NSString *)openChatIdsByChatIdsURL {
    return [self baseURLAppendingPath:@"v4/getOpenChatIDsByChatIDs"];
}

+ (NSString *)chatIDsByOpenIDsURL {
    return [self baseURLAppendingPath:@"getChatIDsByOpenIDs"];
}

+ (NSString *)syncClientAuthURL {
    return [self baseURLAppendingPath:@"SyncClientAuth"];
}

+ (NSString *)syncClientAuthBySessionURL {
    return [self baseURLAppendingPath:@"syncClientAuthBySession"];
}

+ (NSString *)editorSearchURL {
    return [self baseURLAppendingPath:@"searchPeople"];
}

+ (NSString *)envConfigURL {
    return [self baseURLAppendingPath:kEMANetworkAPIPath_getEnvConfig];
}

+ (NSString *)lightServiceInvokeURL {
    return [self baseURLAppendingPath:@"light_service/invoke"];
}

+ (NSString *)getScopesURL {
    return [self baseURLAppendingPath:@"api/GetScopes"];
}

+ (NSString *)getTenantAppScopesURL {
    return [self baseURLAppendingPath:@"GetTenantAppScopes"];
}

+ (NSString *)applyAppScopeStatusURL {
    return [self baseURLAppendingPath:@"ApplyAppScopeStatus"];
}

+ (NSString *)applyAppScopeURL {
    return [self baseURLAppendingPath:@"ApplyAppScope"];
}

/*----------------------------------------------------------*/
#pragma mark                OpenPlatform
/*----------------------------------------------------------*/

+ (NSString *)uploadAuthURL {
    return [self urlWithHost:self.domainConfig.openDomain path:@"/open-apis/id_verify/v1/upload_auth_info"];
}

+ (NSString *)hasAuthURL {
    return [self urlWithHost:self.domainConfig.openDomain path:@"/open-apis/mina/human_authentication/v1/identity"];
}

+ (NSString *)getUserTicketURL {
     return [self urlWithHost:self.domainConfig.openDomain path:@"/open-apis/mina/human_authentication/v1/user_ticket"];
}

+ (NSString *)getUserTicketWithCodeURL {
    return [self urlWithHost:self.domainConfig.openDomain path:@"/open-apis/mina/human_authentication/v1/user_ticket_with_code"];
}

+ (NSString *)authConfirmURL {
    // ⚠️注意这里使用的是老的域名集合 openMinaDomain（已废弃）
    return [self urlWithHost:self.domainConfig.openMinaDomain path:@"/open-apis/id_verify/v1/confirm"];
}

+ (NSString *)uploadAppLoadInfo {
    return [self urlWithHost:self.domainConfig.openDomain path:@"/open-apis/mina/UploadAppLoadInfo"];
}

+ (NSString *)uploadAppInstallInfo {
    return [self urlWithHost:self.domainConfig.openDomain path:@"/open-apis/mina/UploadAppInstallInfo"];
}

+ (NSString *)getUpdateAppInfos {
    return [self urlWithHost:self.domainConfig.openDomain path:@"/open-apis/mina//GetUpdateAppInfos"];
}

/*----------------------------------------------------------*/
#pragma mark                Others
/*----------------------------------------------------------*/

+ (NSString *)configCenterURL {
    /// 配置中心的域名是mpConfig，path是/config/get
    return [self urlWithHost:self.domainConfig.configDomain path:@"/config/get"];
}

+ (NSString *)unsupportedContextURL {
    NSString *language = [BDPApplicationManager language];
    double timestamp = ([[NSDate date] timeIntervalSince1970] * 1000); // 毫秒
    // 默认语言：英文
    return [NSString stringWithFormat:@"https://%@/ee/spm/lark/m/statics/html/unsupport.html?language=%@&r=%.0f", self.domainConfig.pstatpDomain, language ?: @"en_US", timestamp];
}

+ (NSString *)vodFetcherUrl:(NSString *)playAuthToken {
    return [NSString stringWithFormat:@"https://%@/?%@", self.domainConfig.vodDomain, playAuthToken];
}

+ (NSString *)addressBaseUrl {
    return [NSString stringWithFormat:@"https://%@/mini_program/address", self.domainConfig.snssdkDomain];
}

+ (NSString *)webviewURLNotSupportPage {
    return [NSString stringWithFormat:@"https://%@/ee/spm/lark/m/statics/html/url-not-support.html", self.domainConfig.pstatpDomain];
}

+ (NSString *)clickProgramReportURL {
    return [NSString stringWithFormat:@"https://%@/mini_program/click_program/v1/", self.domainConfig.snssdkDomain];
}

+ (NSString *)serviceRefererURL {
    return [NSString stringWithFormat:@"https://%@", self.domainConfig.referDomain];
}

@end
