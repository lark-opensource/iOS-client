//
//  BDTrustEnclave.h
//  BDTrustEnclave
//
//  Created by chenzhendong.ok@bytedance.com on 2022/6/4.
//

#import <Foundation/Foundation.h>
#import "BDTGNetwork.h"
#import "BDTicketGuard.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const BDTGTicketGuardUseTicketHeaderErrorKey;
FOUNDATION_EXPORT NSString *const BDTGTicketGuardHeaderResultKey;
FOUNDATION_EXPORT NSString *const BDTGTicketGuardHeaderServerDataKey;
FOUNDATION_EXPORT NSString *const BDTGTicketGuardHeaderReePublicKeyKey;
FOUNDATION_EXPORT NSString *const BDTGTicketGuardHeaderClientDataKey;
FOUNDATION_EXPORT NSString *const BDTGTicketGuardHeaderClientCertKey;
FOUNDATION_EXPORT NSString *const BDTGTicketGuardHeaderClientCSRKey;

FOUNDATION_EXPORT NSString *const BDTGTicketGuardAttachedTicketValueKey;
FOUNDATION_EXPORT NSString *const BDTGTicketGuardAttachedTicketNameKey;


@interface BDTGTicketManager : NSObject

@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *serverDataMap;

+ (instancetype _Nonnull)sharedInstance;

- (void)start;

/// 给获取ticket的请求添加 bd-ticket-guard-version、bd-ticket-guard-client-cert or bd-ticket-guard-client-csr
/// error code：900 - 参数非法，request 为空；公私钥创建失败；
///          901 - 参数非法，request header 中没有 bd-ticket-guard-tag；
///          3000 - 公钥解析失败
///          3002 - csr签名失败
///          -1 - 未知错误 详见 error.localizedDescription；
/// - Parameter request: Http请求
- (NSError *_Nullable)handleGetTicketRequest:(id<BDTGHttpRequest>)request;

/// 处理返回ticket的请求response header中的bd-ticket-guard-server-data
/// error code：900 - 参数非法，request 为空；公私钥创建失败；
///          901 - 参数非法，request header 中没有 bd-ticket-guard-tag；
/// - Parameters:
///   - response: Http请求 response
///   - request: Http请求 request
- (void)handleGetTicketResponse:(id<BDTGHttpResponse>)response request:(id<BDTGHttpRequest>)request;

/// 给使用ticket的请求添加 bd-ticket-guard-version、bd-ticket-guard-client-cert、bd-ticket-guard-client-data
/// error code：900 - 参数非法，request 为空；公私钥创建失败；
///          902 - 参数非法，request header 中没有 bd-ticket-guard-target；
///          4000 - 本地无证书；
///          4001 - 本地无对应的server data；
///          3002 - 签名失败
/// - Parameter request: Http请求 request
- (NSError *_Nullable)handleUseTicketRequest:(id<BDTGHttpRequest>)request;

/// 上报验签结果
/// - Parameters:
///   - response: 验签请求回包
///   - request: 验签请求
- (void)handleUseTicketResponse:(id<BDTGHttpResponse>)response request:(id<BDTGHttpRequest>)request;

@end


@interface BDTGTicketManager (Adapter)

- (void)addNetworkFilter;

@end


@interface BDTicketGuard (TicketManagerVersion)

@property (class, nonatomic, copy, readonly, nullable) NSString *ticketGuardVersion;
@property (class, nonatomic, copy, readonly, nullable) NSString *ticketGuardIterationVersion;
@property (class, nonatomic, assign, readonly) BOOL enableRee;

@end


@interface BDTicketGuard (CertLoader)

+ (void)p_preloadCert;

+ (void)p_loadCertWithCompletion:(void (^)(NSError *_Nullable))completion;

@end


NS_ASSUME_NONNULL_END
