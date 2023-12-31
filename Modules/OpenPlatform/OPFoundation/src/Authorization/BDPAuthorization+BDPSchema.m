//
//  BDPAuthorization+Schema.m
//  Timor
//
//  Created by liuxiangxin on 2019/12/10.
//

#import "BDPAuthorization+BDPSchema.h"
#import "BDPModel.h"
#import "BDPUtils.h"
#import "BDPSDKConfig.h"
#import "BDPTimorClient.h"
#import "TMACustomHelper.h"
#import "BDPRouteMediator.h"
#import "BDPCommonManager.h"
#import "BDPSchema+Private.h"
#import "NSArray+BDPExtension.h"
#import "BDPSchemaCodec+Private.h"
#import "BDPAppMetaUtils.h"

#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/EMAFeatureGating.h>

@implementation BDPAuthorization (BDPSchema)

- (BOOL)checkAuthorizationURL:(NSString *)url authType:(BDPAuthorizationURLDomainType)authType
{
    // 对齐微信，在测试版本不对url进行校验
    BOOL isReleaseCandidateMode = [BDPAppMetaUtils metaIsReleaseCandidateModeForVersionType:self.source.uniqueID.versionType];
    if (!isReleaseCandidateMode) {
        return YES;
    }

    if (BDPRouteMediator.sharedManager.checkDomainsForUniqueID && !BDPRouteMediator.sharedManager.checkDomainsForUniqueID(self.source.uniqueID)) {
        return YES;
    }
    
    if (BDPIsEmptyString(url)) {
        return NO;
    }
    
    // 检查schema
    BOOL containsSchema = NO;
    NSArray* schemaList = [self defaultSchemaSupportList];
    for (NSString* schema in schemaList) {
        NSString* fullSchema = [schema stringByAppendingString:@"://"];
        if ([url hasPrefix:fullSchema]) {
            containsSchema = YES;
            break;
        }
    }
    if (!containsSchema) {
        return NO;
    }

    NSURL *requestURL = [TMACustomHelper URLWithString:url relativeToURL:nil];
    if (!requestURL) {
        return NO;
    }
    
    NSArray *domainsArray = [self domainsListWithAuthType:authType];
    if (!domainsArray.count) {
        return NO;
    }
    
    NSString *host = requestURL.host;
    
    __block BOOL authResult = [domainsArray containsObject:host];
    
    //webView的支持泛域名，所以在没有严格匹配的情况下还需要进行泛域名匹配
    if (!authResult && authType == BDPAuthorizationURLDomainTypeWebView) {
        [domainsArray enumerateObjectsUsingBlock:^(NSString *  _Nonnull domain, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *wildDomain = domain;
            //把前面所有的'.'都去掉
            while ([wildDomain hasPrefix:@"."]) {
                if (wildDomain.length) {
                    wildDomain = [wildDomain substringFromIndex:1];
                }
            }
            wildDomain = [NSString stringWithFormat:@".%@", wildDomain];
            BOOL isMatch = [host hasSuffix:wildDomain];
            if (isMatch) {
                authResult = YES;
                *stop = YES;
            }
        }];
    }
    
    return authResult;
}

- (NSArray *)defaultSchemaSupportList;
{
    BOOL isReleaseCandidateMode = [BDPAppMetaUtils metaIsReleaseCandidateModeForVersionType:self.source.uniqueID.versionType];
    if (!isReleaseCandidateMode) {
        // 对齐微信，在测试版本放行http
        return @[@"http",@"https",@"wss"];
    }
    
    return @[@"https",@"wss"];
}

- (NSArray *)webViewComponentSpecialSchemaSupportList
{
    return @[@"tel", @"mailto", @"sms", @"data"];
}

- (NSArray *)domainsListWithAuthType:(BDPAuthorizationURLDomainType)authType
{

    NSDictionary *domainsAuthDict = self.source.domainsAuthMap;
    NSString *domainsKey = @"unknown";
    
    if (authType == BDPAuthorizationURLDomainTypeWebView) domainsKey = @"webview";
    else if (authType == BDPAuthorizationURLDomainTypeRequest) domainsKey = @"request";
    else if (authType == BDPAuthorizationURLDomainTypeUpload) domainsKey = @"upload";
    else if (authType == BDPAuthorizationURLDomainTypeDownload) domainsKey = @"download";
    else if (authType == BDPAuthorizationURLDomainTypeWebSocket) domainsKey = @"socket";
    else if (authType == BDPAuthorizationURLDomainTypeSchemaHost) domainsKey = @"schema_host";
    else if (authType == BDPAuthorizationURLDomainTypeSchemaAppIds) domainsKey = @"appids";
    else if (authType == BDPAuthorizationURLDomainTypeWebViewComponentSchema) domainsKey = @"webview_schema";
    
    NSArray *domainsArray = [domainsAuthDict bdp_arrayValueForKey:domainsKey];
    
    // webview由于会有兜底页面，这里把兜底页面的url也加入白名单
    if (authType == BDPAuthorizationURLDomainTypeWebView) {
        if ([domainsArray count] > 0) {
            domainsArray = [domainsArray arrayByAddingObjectsFromArray:[BDPSDKConfig sharedConfig].defaultWebViewHostWhiteList];
        } else {
            domainsArray = [BDPSDKConfig sharedConfig].defaultWebViewHostWhiteList;
        }
    }
    
    return domainsArray;
}

/// 目前是 openScheme API、Preview Image 扫描非 http/https 二维码、Block场景下的WebSocket  这几个场景有调用
- (BOOL)checkSchema:(NSURL **)url uniqueID:(BDPUniqueID *)uniqueID errorMsg:(NSString **)failErrMsg {
    if (BDPRouteMediator.sharedManager.checkDomainsForUniqueID && !BDPRouteMediator.sharedManager.checkDomainsForUniqueID(self.source.uniqueID)) {
        return YES;
    }
    
    if (url == NULL) {
        if (failErrMsg != NULL) {
            *failErrMsg = @"URL is NULL";
        }
        return NO;
    }
    
    NSURL *dest = *url;
    
    // 宿主列表为空
    BDPCommon *common = BDPCommonFromUniqueID(self.source.uniqueID);
    NSArray *hostList = [common.auth domainsListWithAuthType:BDPAuthorizationURLDomainTypeSchemaHost];
    if (![hostList count]) {
        if (failErrMsg != NULL) {
            *failErrMsg = @"hostList is NULL";
        }
        return NO;
    }
    
    // schema 的 V2 版本会对 schema 进行合法性校验,由于 openSchema 支持任意 schema, 未必是小程序/小游戏
    // 所以这里改为拆分原始 schema 字符串取特定值的方式,而不能借助于 BDPSchema 类.
    __block NSString *hostString = nil;
    __block NSString *appidString = nil;
    [BDPSchemaCodec separateProtocolHostAndParams:dest.absoluteString syncResultBlock:^(NSString *protocol, NSString *host, NSString *fullHost, NSDictionary *params) {
        hostString = host;
        appidString = [params bdp_stringValueForKey:@"app_id"];
    }];
    
    // schema转跳限制 - host 在 schema_host 里的才能跳
    if ([hostString length] == 0 || (![hostList containsObject:hostString])) {
        if (failErrMsg != NULL) {
            *failErrMsg = @"unauthorized schema host";
        }
        return NO;
    }
    
    if ([hostString isEqualToString:SCHEMA_APP]) {
    } else {
        // 跳转其他业务
        return YES;
    }
    if (failErrMsg != NULL) {
        *failErrMsg = @"unauthorized appid param";
    }
    return NO;
}

/// 在schema中添加origin_entrance参数，用于埋点上报
/// 技术文档：https://bytedance.feishu.cn/space/doc/doccn1kFvSYzjjSnnbVk1Ar6fHg#
- (NSURL *)urlByAddEntranceInfoToURL:(NSURL *)originalURL withCurrentScheme:(BDPSchema *)currentScheme {
    if ((!currentScheme.launchFrom.length && !currentScheme.originEntrance.length) ||
        [originalURL.absoluteString containsString:BDPSchemaBDPLogKeyOriginEntrance]) {
        return originalURL;
    }
    NSError *error = nil;
    BDPSchemaCodecOptions *schemeOptions = [BDPSchemaCodec schemaCodecOptionsFromURL:originalURL error:&error];
    if (error) {
        return originalURL;
    }
    
    NSString *entranceValue = nil;
    if (currentScheme.originEntrance.length) {
        // 先从当前scheme拿
        entranceValue = currentScheme.originEntrance;
    } else if (currentScheme.launchFrom.length) { \
        // 尝试从当前scheme生成
        NSString *location = [currentScheme location];
        entranceValue = [NSString stringWithFormat:@"{\"oe_launch_from\":\"%@\", \"oe_location\":\"%@\"}", currentScheme.launchFrom, BDPSafeString(location)];
    }
    if (entranceValue.length) {
       [schemeOptions.bdpLog setObject:entranceValue forKey:BDPSchemaBDPLogKeyOriginEntrance];
        NSURL *resultURL = [BDPSchemaCodec schemaURLFromCodecOptions:schemeOptions error:&error];
        return error ? originalURL : resultURL;
    }
    return originalURL;
}

@end
