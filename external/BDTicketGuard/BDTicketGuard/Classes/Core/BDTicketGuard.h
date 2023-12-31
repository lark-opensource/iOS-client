//
//  BDTicketGuard.h
//  BDTicketGuard
//
//  Created by ByteDance on 2022/12/19.
//

#import <Foundation/Foundation.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import "BDTGNetwork.h"
#import "BDTGDefines.h"

NS_ASSUME_NONNULL_BEGIN

#define BDTGTimeoutForever -1
#define BDTGTimeoutWait 5

#define BDTGRequestAndResponseSnapshot(aRequest, aResponse) [BDTicketGuard snapshotForRequest:aRequest response:aResponse]
#define BDTGTrackFullPath(ticketName, aEventType, aError, aExtraInfo) !BDTicketGuard.config.enableFullPathTrack ?: [BDTicketGuard trackFullPathWithTicketName:ticketName eventType:aEventType error:aError extraInfo:aExtraInfo]

typedef BOOL (^BDTGEventTrackControllBlock)(NSString *eventName, NSDictionary *params);


@interface TTHttpRequest (BDTGAdditions) <BDTGHttpRequest>

@end


@interface TTHttpResponse (BDTGAdditions) <BDTGHttpResponse>

@end


@interface BDTicketGuardConfig : NSObject

@property (nonatomic, assign) BOOL initializeStorage;
@property (nonatomic, assign) BOOL enableFullPathTrack;
@property (nonatomic, assign) BOOL enableStorageOptimize;
@property (nonatomic, assign) BOOL enableKeyChainStorage;

@end


@interface BDTicketGuard : NSObject

@property (nonatomic, strong, class, readonly, nullable) BDTicketGuardConfig *config;

/// 域名
@property (nonatomic, copy, class, readwrite, nullable) NSString *domain;

/// SDK版本号
@property (nonatomic, copy, class, readonly, nonnull) NSString *sdkVersion;

/// 客户端证书
@property (nonatomic, copy, class, readonly, nullable) NSString *clientCert;

/// 服务端证书序列号
@property (nonatomic, copy, class, readonly, nullable) NSString *serverCertSN;

/// 自定义埋点上报实现
@property (nonatomic, copy, class, readwrite, nullable) BDTGEventTrackControllBlock eventTrackControllBlock;

/// 初始化
/// - Parameter initializeStorage: 是否初始化存储，避免出现卡死，预留一个开关
+ (void)configure:(BDTicketGuardConfig *)config;

/// 加载公私钥
+ (void)start;

@end


@interface BDTicketGuard (CertManager)

/// 预加载证书
+ (void)preloadCert;

/// 加载证书
/// - Parameter completion: 回调
+ (void)loadCertWithCompletion:(nullable void (^)(NSError *_Nullable error))completion;

@end


@interface BDTGTSSignItem : NSObject

@property (nonatomic, copy, nullable) NSString *ticket;
@property (nonatomic, copy, nullable) NSString *tsSign;

@end


@interface BDTicketGuard (TicketManager)


/// 获取本地保存的Ticket
/// - Parameters:
///   - path: 下发Ticket的请求Path
///   - tag: 自定义tag
+ (NSString *_Nullable)ticketForRequestPath:(NSString *)path tag:(NSString *)tag;

/// 解析返回Response中的TsSign
/// - Parameter response: 请求response
+ (NSArray<BDTGTSSignItem *> *)tsSignItemsInResponse:(id<BDTGHttpResponse>)response;

/// 给获取ticket的请求添加 bd-ticket-guard-version、bd-ticket-guard-client-cert or bd-ticket-guard-client-csr
/// error code：900 - 参数非法，request 为空；公私钥创建失败；
///          901 - 参数非法，request header 中没有 bd-ticket-guard-tag；
///          3000 - 公钥解析失败
///          3002 - csr签名失败
///          -1 - 未知错误 详见 error.localizedDescription；
/// - Parameter request: Http请求
+ (NSError *_Nullable)handleGetTicketRequest:(id<BDTGHttpRequest>)request;

/// 处理返回ticket的请求response header中的bd-ticket-guard-server-data
/// error code：900 - 参数非法，request 为空；公私钥创建失败；
///          901 - 参数非法，request header 中没有 bd-ticket-guard-tag；
/// - Parameters:
///   - response: Http请求 response
///   - request: Http请求 request
+ (NSError *_Nullable)handleGetTicketResponse:(id<BDTGHttpResponse>)response request:(id<BDTGHttpRequest>)request;

/// 给使用ticket的请求添加 bd-ticket-guard-version、bd-ticket-guard-client-cert、bd-ticket-guard-client-data
/// error code：900 - 参数非法，request 为空；公私钥创建失败；
///          902 - 参数非法，request header 中没有 bd-ticket-guard-target；
///          4000 - 本地无证书；
///          4001 - 本地无对应的server data；
///          3002 - 签名失败
/// - Parameter request: Http请求 request
+ (NSError *_Nullable)handleUseTicketRequest:(id<BDTGHttpRequest>)request;

/// 添加解析拦截器
+ (void)addTTNetRequestForPassportAccessTokenFilterBlock;

/// 给获取ticket的请求添加 bd-ticket-guard-version、bd-ticket-guard-client-cert or bd-ticket-guard-client-csr 证书和票据签名由外部自行管理
/// - Parameter request: 请求
+ (NSError *)addHeadersToGetTicketRequest:(id<BDTGHttpRequest>)request;

/// 给获取ticket的请求添加 bd-ticket-guard-version、bd-ticket-guard-client-cert or bd-ticket-guard-client-csr 证书和票据签名由外部自行管理
/// - Parameter request: 请求
+ (NSError *)addHeadersToGetTicketRequest:(id<BDTGHttpRequest>)request ticketName:(NSString *_Nullable)ticketName;

/// 给使用ticket的请求添加 bd-ticket-guard-version、bd-ticket-guard-client-cert、bd-ticket-guard-client-data 相关参数从外部传入
/// - Parameters:
///   - request: 请求
///   - ticket: 票据
///   - tsSign: 票据签名
+ (NSError *)addHeadersToUseTicketRequest:(id<BDTGHttpRequest>)request ticket:(NSString *)ticket tsSign:(NSString *)tsSign;

/// 给使用ticket的请求添加 bd-ticket-guard-version、bd-ticket-guard-client-cert、bd-ticket-guard-client-data 相关参数从外部传入
/// - Parameters:
///   - request: 请求
///   - ticket: 票据
///   - tsSign: 票据签名
///   - ticketName: 票据名称
+ (NSError *)addHeadersToUseTicketRequest:(id<BDTGHttpRequest>)request ticket:(NSString *)ticket tsSign:(NSString *)tsSign ticketName:(NSString *_Nullable)ticketName;

/// 票据更新
/// - Parameters:
///   - requst: 请求
///   - response: 回包
///   - ticketName: 票据名称
///   - ticket: 票据
///   - tsSign: 签名
+ (void)ticketDidUpdateWithRequset:(id<BDTGHttpRequest>)requst response:(id<BDTGHttpResponse>)response ticketName:(NSString *)ticketName ticket:(NSString *)ticket tsSign:(NSString *)tsSign;

/// 全链路跟踪
/// - Parameters:
///   - ticketName: 票据名称
///   - eventType: 时间
///   - error: 错误
///   - extraInfo: 参数
+ (void)trackFullPathWithTicketName:(NSString *)ticketName eventType:(NSString *)eventType error:(NSError *_Nullable)error extraInfo:(NSDictionary *_Nullable)extraInfo;

/// 请求快照
/// - Parameters:
///   - request: 请求
///   - response: 回包
+ (NSDictionary *)snapshotForRequest:(id<BDTGHttpRequest>)request response:(id<BDTGHttpResponse>)response;

@end

#pragma mark - Decrypt


@interface BDTicketGuard (DecryptAdapter)

/// 解密数据
/// - Parameters:
///   - error: 错误
+ (NSData *_Nullable)decryptData:(NSData *_Nonnull)fromData error:(NSError **)error;

@end


@interface BDTicketGuard (Decrypt)

/// 设置解密超时时间，在主线程调用时可以设置超时时间，避免主线程卡死，超时时间必须大于0
/// - Parameters:
///   - timeout: 秒
///   - error: 错误
+ (NSData *_Nullable)decryptData:(NSData *_Nonnull)fromData timeout:(NSTimeInterval)timeout error:(NSError **)error;

/// 解密
/// - Parameter error: 错误 错误码详见 BDTGErrorCode中的 BDTGErrorCodeECDHKey 和 BDTGErrorCodeDecrypt
+ (NSString *)decryptHexString:(NSString *_Nonnull)fromString error:(NSError *__autoreleasing _Nullable *)error;

/// 设置解密超时时间，在主线程调用时可以设置超时时间，避免主线程卡死，超时时间必须大于0
/// - Parameters:
///   - timeout: 秒
///   - error: 错误 错误码详见 BDTGErrorCode中的 BDTGErrorCodeECDHKey 和 BDTGErrorCodeDecrypt
+ (NSString *)decryptHexString:(NSString *_Nonnull)fromString timeout:(NSTimeInterval)timeout error:(NSError **)error;

/// 解密
/// - Parameter error: 错误 错误码详见 BDTGErrorCode中的 BDTGErrorCodeECDHKey 和 BDTGErrorCodeDecrypt
+ (NSString *)decryptBase64String:(NSString *_Nonnull)fromString error:(NSError *__autoreleasing _Nullable *)error;

/// 设置解密超时时间，在主线程调用时可以设置超时时间，避免主线程卡死，超时时间必须大于0
/// - Parameters:
///   - timeout: 秒
///   - error: 错误 错误码详见 BDTGErrorCode中的 BDTGErrorCodeECDHKey 和 BDTGErrorCodeDecrypt
+ (NSString *)decryptBase64String:(NSString *_Nonnull)fromString timeout:(NSTimeInterval)timeout error:(NSError **)error;


@end

NS_ASSUME_NONNULL_END
