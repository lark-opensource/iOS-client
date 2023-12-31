//
//  TTAdSplashBanResponseModel.h
//  TTAdSplashSDK
//
//  Created by resober on 2018/11/2.
//

#import <Foundation/Foundation.h>
#import "TTAdSplashBanRequestModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTAdSplashBanResponseModel : NSObject
#pragma mark - Header

/**
 *  udp socket返回的原始数据
 */
@property (nonatomic, strong) NSData *rawData;
/**
 *  不携带MAC的原始数据，正常情况下应为rawData的前 15 bytes
 *  TransactionID 4Bytes + Type 1Byte + Content 10Bytes
 */
@property (nonatomic, strong) NSData *rawDataWithoutMAC;

/**
 *  4字节, 唯一标识一次Query
 */
@property (nonatomic, assign) uint32_t transactaionID;

/**
 *  1字节,报文类型,
 *  目前仅设SSQ(0),SSA(1)两种, 代表SplashSwitchQuery和SplashSwitchAnswer.
 */
@property (nonatomic, assign) uint8_t type;
#pragma mark - Content


/**
 *  Content 10Byte：10个字节的随机字符串
 *
 *  按照传入的random number的十进制表示中每个数值位的值去读取随机字符串的值，
 *  将每位值的对应ascii码相加，得到的和的最后一digit是否大于4，大于4代表投放开屏，小于等于4代表停投
 */
@property (nonatomic, strong) NSData *content;

/// timestamp 8 byte: 打包下发的正确时间戳，做时间校验，本地可能因为用户调整手机时间而不准确
@property (nonatomic, assign) NSTimeInterval timestamp;

#pragma mark - MAC

/**
 *  使用Flag定义的算法, 计算外层报文的摘要值，也就是整个明文报文的Mac值
 */
@property (nonatomic, strong) NSString *MAC;

#pragma mark - UDP功能升级增加启动清埋开屏功能

/// udp指令可以生效的平台
@property (nonatomic, assign) int64_t platform;
/// udp指令可以执行的操作
@property (nonatomic, assign) int64_t action;
/// udp指令cids的数据长度
@property (nonatomic, assign) int64_t cidsLen;
/// udp指令cids内容
@property (nonatomic, copy) NSArray<NSNumber *> *cids;
/// udp指令ClearCache的数据长度
@property (nonatomic, assign) int64_t clearCacheLen;
/// udp指令ClearCache内容
@property (nonatomic, copy) NSArray<NSString *> *clearCaches;
/// udp指令LogExtra的数据长度
@property (nonatomic, assign) int64_t logExtraLen;
/// udp指令LogExtra
@property (nonatomic, copy) NSString *logExtra;

#pragma mark - RequestModel传入的数据


/**
 *  1字节, 区分不同消息摘要算法
 *  摘要算法, 0-MD5, 1-SHA1, 2-SHA256, 3-SHA512
 */
@property (nonatomic, assign) TTAdSplashBanRequestModelEncryption flag;

/**
 *  8字节，一个10个数字的二进制表示，使用CSPRNG生成的随机数，并且必须是十个的数字。
 *  random number取值范围：[10 0000 0000, 99 9999 9999]
 */
@property (nonatomic, assign) uint64_t randomNum;

@property (nonatomic, weak) TTAdSplashBanRequestModel *reqModel;

#pragma mark - Methods

/**
 *  @param data 服务端返回的数据
 *  @param reqModel 此响应对应的请求数据
 *  encryptionFlag 对应的请求使用的摘要算法
 *  randomNumber 对应的请求使用的随机数
 *  reqTranscationId 对应请求的transcationId
 *  @return 根据服务端返回的bytes数据以及对应的请求模型生成responeModel，如果data数据不合法则会返回nil；
 */
- (nullable instancetype)initWithData:(NSData *)data
                         requestModel:(TTAdSplashBanRequestModel *)reqModel;

/**
 *  校验返回数据的合法性，使用flag摘要算法校验MAC
 */
- (BOOL)isValidModel;

/**
 *  是否需要显示广告，计算过程:
 *
 *  按照传入的random number的十进制表示中每个数值位的值去读取随机字符串的值，
 *  将每位值的对应ascii码相加，得到的和的最后一digit是否大于4，大于4代表投放开屏，小于等于4代表停投
 */
- (BOOL)shouldShowAd;
@end

NS_ASSUME_NONNULL_END
