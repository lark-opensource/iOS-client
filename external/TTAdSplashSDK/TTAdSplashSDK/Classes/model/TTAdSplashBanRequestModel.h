//
//  TTAdSplashBanRequestModel.h
//  TTAdSplashSDK
//
//  Created by resober on 2018/11/2.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

// 报文类型
typedef NS_ENUM(uint8_t, TTAdSplashBanRequestModelType) {
    TTAdSplashBanRequestModelTypeQuery = 0, ///< SplashSwitchQuery
    TTAdSplashBanRequestModelTypeAnwser ///< SplashSwitchAnswer
};

// 摘要算法
typedef NS_ENUM(uint8_t, TTAdSplashBanRequestModelEncryption) {
    TTAdSplashBanRequestModelEncryptionMD5 = 0,
    TTAdSplashBanRequestModelEncryptionSHA1,
    TTAdSplashBanRequestModelEncryptionSHA256,
    TTAdSplashBanRequestModelEncryptionSHA512
};

@interface TTAdSplashBanRequestModel : NSObject
#pragma mark - Header

// 文档：https://docs.bytedance.net/doc/FOYDI7DO8dUZUZphDcsCPf
/**
 *  4字节, 唯一标识一次Query
 */
@property (nonatomic, assign) uint32_t transactaionID;

/**
 *  4字节, 区分报文版本序号的二进制表示，当前为5
 */
@property (nonatomic, assign) uint32_t version;

/**
 *  1字节,报文类型,
 *  目前仅设SSQ(0),SSA(1)两种, 代表SplashSwitchQuery和SplashSwitchAnswer.
 */
@property (nonatomic, assign) uint8_t type;

/**
 *  1字节, 区分不同消息摘要算法
 *  摘要算法, 0-MD5, 1-SHA1, 2-SHA256, 3-SHA512
 */
@property (nonatomic, assign) uint8_t flag;

#pragma mark - Content


/**
 *  4字节，公司内部定义的app id.
 */
@property (nonatomic, strong) NSString *appID;

/**
 *  8字节，精确到毫秒的时间戳的二进制标示
 */
@property (nonatomic, strong) NSString *timeStamp;

/**
 *  8字节，一个10个数字的二进制表示，使用CSPRNG生成的随机数，并且必须是十个的数字。
 *  random number取值范围：[10 0000 0000, 99 9999 9999]
 */
@property (nonatomic, assign) uint64_t randomNum;

/**
 *  4字节，APP版本信息
 */
@property (nonatomic, assign) uint32_t appVersion;

/**
 *  4字节，系统版本信息
 */
@property (nonatomic, assign) uint32_t systemVersion;

#pragma mark - MAC

/**
 *  使用Flag定义的算法, 计算外层报文的摘要值，也就是整个明文报文的Mac值
 */
@property (nonatomic, strong) NSString *MAC;

/**
 *  依据当前时间，生成一个模板model。
 *  @return 模板model
 */

#pragma mark - Other


/**
 *  来源是否是热启动
 */
@property (nonatomic, assign) BOOL formHotLaunch;

/**
 *  发送请求到返回数据间的耗时 单位秒
 */
@property (nonatomic, assign) NSTimeInterval costTime;

/**
 *  请求发送的地址
 */
@property (nonatomic, copy) NSString *requestAddr;

/**
 *  准备发送请求的时间
 */
@property (nonatomic, assign) NSTimeInterval startRequestTime;

/**
 *  按照udp返回数据的维度进行rank排序（只关乎返回的顺序）
 */
@property (nonatomic, assign) NSUInteger rank;

/**
 *  根据时间和一些随机数据生成请求模型，不包含MAC
 */
+ (instancetype)templateRequestModel;

/**
 *  根据当前model中所设定flag选择摘要算法对数据进行处理，生成请求所需的data
 */
- (NSData *)requestData;
@end

NS_ASSUME_NONNULL_END
