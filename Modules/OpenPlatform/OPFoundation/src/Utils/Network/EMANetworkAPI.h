//
//  EMANetworkAPI.h
//  EEMicroAppSDK
//
//  Created by houjihu on 2018/12/20.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OPEnvTypeHelper.h"
@class MicroAppDomainConfig;
NS_ASSUME_NONNULL_BEGIN

@interface EMAAPI : NSObject

/// 判断是否是开放平台域名
+ (BOOL)isOpenPlatformRequestForURLString:(NSString *)urlString;

// 是否需要增加 X-Session-ID Header
+ (BOOL)needLarkSessionForURLString:(NSString *)urlString;

+ (void)printAllURL;

+ (NSString *)configCenterURL;

+ (NSString *)userLoginURL;

+ (NSString *)checkSessionURL;

+ (NSString *)userInfoURL;

+ (NSString *)userInfoH5URL;

+ (NSString *)appMetaURL;

+ (NSString *)batchAppMetaURL;

/// 卡片meta请求urls数组（目前只有一个元素）
+ (NSArray * _Nonnull)cardMetaUrls;

+ (NSString *)userIdURL;

+ (NSString *)userIdsByOpenIDsURL;

+ (NSString *)chatIdURL;

+ (NSString *)chatIdByOpenChatIdURL;

+ (NSString *)openIdURL;

+ (NSString *)contactInfosURL;

+ (NSString *)openChatIdsByChatIdsURL;

+ (NSString *)chatIDsByOpenIDsURL;

+ (NSString *)uploadAuthURL;

+ (NSString *)hasAuthURL;

// 获取活体检测票据
+ (NSString *)getUserTicketURL;
+ (NSString *)getUserTicketWithCodeURL;

+ (NSString *)authConfirmURL;

/// 同步用户个人资源授权信息url
+ (NSString *)syncClientAuthURL;

/// 新版同步用户个人资源授权信息url，各形态通用，需要传入对应形态的session，https://bytedance.feishu.cn/docs/doccndU63SzTSAP6gR9npBT8Gzg#mIf88T
+ (NSString *)syncClientAuthBySessionURL;

+ (NSString *)editorSearchURL;

+ (NSString *)unsupportedContextURL;

+ (NSString *)vodFetcherUrl:(NSString *)playAuthToken;

+ (NSString *)addressBaseUrl;

+ (NSString *)webviewURLNotSupportPage;

+ (NSString *)clickProgramReportURL;

+ (NSString *)serviceRefererURL;

+ (NSString *)uploadAppLoadInfo;

+ (NSString *)uploadAppInstallInfo;

+ (NSString *)getUpdateAppInfos;

/// 获取在对应环境(比如SAAS,KA)下的业务配置
+ (NSString *)envConfigURL;

+ (NSString *)lightServiceInvokeURL;

/// 不需要tt.login获取scope信息
+ (NSString *)getScopesURL;

+ (NSString *)getTenantAppScopesURL;

+ (NSString *)applyAppScopeStatusURL;

+ (NSString *)applyAppScopeURL;
@end

NS_ASSUME_NONNULL_END
