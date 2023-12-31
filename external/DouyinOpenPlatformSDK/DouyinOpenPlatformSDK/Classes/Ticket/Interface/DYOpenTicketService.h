//
//  DYOpenTicketService.h
//  DouyinOpenPlatformSDK-af734e60
//
//  Created by arvitwu on 2023/4/3.
//

#import <Foundation/Foundation.h>
#import "DouyinOpenSDKConstants.h"

/// 请求 clientCode 接口
typedef void(^DYOpenFinishRequestClientCodeBlock)(NSString *_Nullable clientCode, NSError *_Nullable codeError); // 业务异步获取成功后通过此 block 回调
typedef void(^DYOpenRequestClientCodeBlock)(NSString *_Nonnull clientKey, DYOpenFinishRequestClientCodeBlock _Nonnull finishRequestBlock); // 业务发请求

/// OpenAPI 请求 block
typedef void(^DYOpenOpenAPIExtraReqBlock)(NSMutableURLRequest *_Nonnull request, NSString *_Nullable clientTicket); // req 额外操作
typedef void(^DYOpenOpenAPICompleteBlock)(NSDictionary *_Nullable respDict, NSDictionary *_Nullable respHeaderDict, NSError *_Nullable error); // 请求 OpenAPI 的结果回调

@protocol DYOpenTicketService <NSObject>

@required

/// 单例
+ (id <DYOpenTicketService> _Nullable)sharedInstance;

/// 注册获取 client code 的请求回调，业务在 block 里自行发起请求
/// ！！！注意最后需要调用 finishRequestBlock 通知 openSDK 结果 ！！！
/// ！！！注意最后需要调用 finishRequestBlock 通知 openSDK 结果 ！！！
/// ！！！注意最后需要调用 finishRequestBlock 通知 openSDK 结果 ！！！
/// @param clientKey 开放平台上申请的应用 key
/// @param requestBlock 获取 clientCode 的网络请求操作，一般是由开发者客户端调用开发者服务端封装好的接口（为了安全，客户端不要本地内置 clientSecrect）
- (void)registerClientKey:(NSString *_Nonnull)clientKey requestClientCodeBlock:(DYOpenRequestClientCodeBlock _Nonnull)requestBlock;


/// 使用 client ticket 发送 GET 请求开放平台接口
/// @param domainAndPath 包含 domain + path
/// @param extraReqBlock 可以设置 req header 等参数
/// @param complete 请求回调
/// @return 发起请求的实例，如果没发起请求则返回 nil（如果需要取消请求，可拿此实例自行取消）
- (NSURLSessionTask *_Nullable)requestGETOpenAPIWithDomainAndPath:(NSString *_Nonnull)domainAndPath
                                                    extraReqBlock:(DYOpenOpenAPIExtraReqBlock _Nullable)extraReqBlock
                                                         complete:(DYOpenOpenAPICompleteBlock _Nullable)complete;

/// 使用 client ticket 发送 POST 请求开放平台接口
/// @param domainAndPath 包含 domain + path
/// @param contentType form 或 json 等
/// @param bodyDict body 参数
/// @param extraReqBlock 可以设置 req header 等参数
/// @param complete 请求回调
/// @return 发起请求的实例，如果没发起请求则返回 nil（如果需要取消请求，可拿此实例自行取消）
- (NSURLSessionTask *_Nullable)requestPOSTOpenAPIWithDomainAndPath:(NSString *_Nonnull)domainAndPath
                                                       contentType:(DYOpenNetworkContentType)contentType
                                                          bodyDict:(NSDictionary *_Nullable)bodyDict
                                                     extraReqBlock:(DYOpenOpenAPIExtraReqBlock _Nullable)extraReqBlock
                                                          complete:(DYOpenOpenAPICompleteBlock _Nullable)complete;
/// domain 域名
- (NSString *_Nonnull)clientTicketDomain;

/// 获取本地缓存的 clientTicket（与注册的 clientKey 的一一对应）
- (NSString *_Nullable)getCachedClientTicket;

@end

@interface DYOpenTicketService : NSObject <DYOpenTicketService>

@end
