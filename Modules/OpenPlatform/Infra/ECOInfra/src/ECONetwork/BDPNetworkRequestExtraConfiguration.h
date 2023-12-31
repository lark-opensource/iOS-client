//
//  BDPNetworkConfiguration.h
//  Timor
//
//  Created by 李靖宇 on 2019/11/17.
//

#import <Foundation/Foundation.h>
#import <TTNetworkManager/TTNetworkManager.h>

extern NSString *const kBDPRequestExtraConfigFlagsKey;
extern NSString *const kBDPRequestExtraConfigRequestSerializerClassKey;
extern NSString *const kBDPRequestMethodKey;
extern NSString *const kBDPRequestTypeKey;
extern NSString *const kBDPRequestHeaderFieldKey;
extern NSString *const kBDPRequestProgressAddressKey;
extern NSString *const kBDPRequestConstructingBodyBlockKey;
extern NSString *const kBDPRequestTimeoutKey;
extern NSString *const kBDPRequestDownloadHeaderCallbackKey;
extern NSString *const kBDPRequestDownloadDataCallbackKey;
extern NSString *const kBDPRequestDownloadOffsetKey;
extern NSString *const kBDPRequestDownloadRequestedLengthKey;

extern NSString *const kBDPRequestDownloadDestinationURLKey;
//ForSyncRequestOnly
extern NSString *const kBDPRequestMethodStrKey;

typedef NS_OPTIONS(NSInteger, BDPRequestExtraConfigFlags) {
    BDPRequestNeedCommonParams      = 1 << 0, //是否需要基础参数
    BDPRequestAutoResume            = 1 << 1, //是否返回task时直接rusume
    BDPRequestVerifyRequest         = 1 << 2, //是否要校验request
    BDPRequestIsCustomizedCookie    = 1 << 3, //是否需要定制化的cookie
    BDPRequestCallbackInMainThread  = 1 << 4, //返回block是否需要在主线程中执行
    BDPRequestEnableHttpCache       = 1 << 5, //是否启用http缓存
    
    BDPRequestFlagsDefault = BDPRequestNeedCommonParams| BDPRequestAutoResume
};

typedef NS_ENUM(NSInteger, BDPRequestType) {
    BDPRequestTypeRequestForJson                  = 1,
    BDPRequestTypeRequestForBinary                = 2,
    BDPRequestTypeUpload                          = 3
};

typedef NS_ENUM(NSInteger, BDPRequestMethod) {
    BDPRequestMethodGET       = 1,
    BDPRequestMethodPOST      = 2
};

@interface BDPNetworkRequestExtraConfiguration : NSObject

/// 请求的标志位集合
@property (nonatomic) BDPRequestExtraConfigFlags flags;
/// 请求的类型，具体类型见类型枚举
@property (nonatomic) BDPRequestType type;
/// 请求的http方法，只支持GET和POST，其他方法请使用methodStr，method具有更高的优先级，>0时会覆盖methodStr
@property (nonatomic) BDPRequestMethod method;
/// 请求的http方法，字符串类型，兼容PUT，DELETE等方法
@property (nonatomic,strong) NSString* methodStr;
/// 请求序列化方法的类
@property (nonatomic) Class bdpRequestSerializerClass;
/// 请求的Header
@property (nonatomic,strong) NSDictionary* bdpRequestHeaderField;
/// post请求拼接body的block
@property (nonatomic,strong) TTConstructingBodyBlock constructingBodyBlock;

/// 上传和下载时进度
@property (nonatomic) NSProgress * __autoreleasing *progress;
/// 上传超时时间
@property (nonatomic) NSTimeInterval timeout;

/// 下载响应头的回调
@property (nonatomic,strong) TTNetworkChunkedDataHeaderBlock downloadHeaderCallback;
/// 下载响应体的回调
@property (nonatomic,strong) TTNetworkChunkedDataReadBlock downloadDataCallback;
/// 下载请求的资源偏移量起点
@property (nonatomic) NSInteger offset;
/// 下载请求的资源长度，<=0表示到资源结束
@property (nonatomic) NSInteger requestedLength;
/// 下载文件存储位置
@property (nonatomic,strong) NSURL* downloadDestinationURL;


/// 默认配置，method为GET，type为RequestForJson，flag为Default
+ (BDPNetworkRequestExtraConfiguration*)defaultConfig;
/// 默认配置+修改http方法
/// @param method 请求的http方法
+ (BDPNetworkRequestExtraConfiguration*)defaultConfigWithHttpMethod:(BDPRequestMethod)method;

/// 序列化默认配置，序列化方法的类为BDPHTTPRequestSerializer
+ (BDPNetworkRequestExtraConfiguration*)defaultBDPSerializerConfig;
/// 序列化默认配置+修改http方法
/// @param method 请求的http方法
+ (BDPNetworkRequestExtraConfiguration*)defaultBDPSerializerConfigWithHttpMethod:(BDPRequestMethod)method;

@end

