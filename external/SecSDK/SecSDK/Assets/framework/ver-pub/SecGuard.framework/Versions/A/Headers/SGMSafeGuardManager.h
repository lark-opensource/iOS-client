//
//  HTSSafeGuardManager.h
//  IESAntiSpam
//
//  Created by renfeng.zhang on 2018/1/12.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SGMSafeGuardConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^SGMEncrpytWhiteListBlock)(NSURL *url, NSDictionary *headers);

@interface SGMSafeGuardManager : NSObject

+ (instancetype)sharedManager;

/**
 * 在调用采集API前, 请先调用下面两方法来设置业务平台和代理(需业务方传入参数), 其它方法调用均依赖于该参数设置.
 * 调用一次即可, 勿重复调用, 若存在多次调用, 请确保同一app中SGMSafeGuardPlatform的一致性.
 */
- (void)sgm_startWithConfig:(SGMSafeGuardConfig *)config delegate:(nullable id<SGMSafeGuardDelegate>)delegate;

/**
 * 这个函数是专门为了解决网盟的问题，其他业务请不要用 ！！！
 * delegate需要实现以下方法：
 * - (NSString *)sgm_hostType
 * - (NSString *)sgm_appKey
 * - (NSString *)sgm_customDeviceID
 * - (NSString *)sgm_sessionID
 * - (NSString *)sgm_installChannel
 */
- (void)sgm_startWithHybridDelegate:(NSObject *)delegate;

/**
 *  该函数自动进行安全防护, 该函数被调用后, 程序内部会启用一个定时器, 每3分钟采集一次传感器数据, 30分钟将采集的设备指纹进行上报
 *  该函数会在单独的线程执行, 一旦调用该函数后, 定时器会一直运行, 直到APP被杀死或者服务器下发参数停止安全防护.
 * @description Call sgm_scheduleSafeGuard:YES
 */
- (void)sgm_scheduleSafeGuard;

- (NSDictionary *) sgm_standaloneUUID;

- (NSString *) sgm_rawLocalEnv;

/*
 * @param autoCollect 设为NO不会自动采集数据，依然可以手动触发
 */
- (void)sgm_scheduleSafeGuard:(BOOL)autoCollect;

/**
 *  业务可手动调用下面两个方法来手动的开始/停止安全防护, 该手动调用机制与上面的自动防护机制不冲突
 *  调用start方法后如果没有调用stop方法, 程序内部会自动判断然后在15秒后停止安全防护.用户也可以显式手动的去调用stop方法
 *
 *  @description 同一时间内只能开启一个手动防护
 *  @param scene 使用该字段来区分不同的采集场景.
 */
- (void)sgm_startManualGuardForScene:(NSString *)scene;
- (void)sgm_stopManualGuard;

/**
 * 手动触发指纹采集
 */
- (void)sgm_ManualScheduleSelas;

/**
 * 更新自定义上报信息
 * 在需要上报的自定义信息更新后调用此方法
 */
- (void)updateCustomInfo:(NSDictionary *)customInfoDic;

/*
 * 前置防御自定义函数指针, 会在触发崩溃前调用，注意请使用阻塞方法
 */
- (void)setPreFcActionPtr:(void (* _Nonnull)(forceCrashMask))preFcActionPtr __attribute((deprecated));

/*
 * 设置SDK域名，当前域名
 * SGMHostCategoryInfo, ///< 上报
 * SGMHostCategoryVerify, ///< 验证码
 * SGMHostCategorySenseless, ///< 无感验证
 * SGMHostCategorySelas, ///< 设备指纹
 * SGMHostCategoryLog, ///< 日志
 * @param hostDic 域名字典，域名需要带协议，例如 {@(SGMHostCategoryInfo), @"https://a.inssdk.com"}
 */
- (void)setHostDic:(NSDictionary <NSNumber *, NSString *> *)hostDic;

/*
 * 请求签名白名单，blk返回YES不走签名函数
 */
- (void)setVersionA:(SGMEncrpytWhiteListBlock)blk;

/*
 * SDK当前版本号
 */
- (NSString *)currentVersion;

+ (instancetype)new  NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end //SGMSafeGuardManager

@interface SGMSafeGuardManager (Encrypt)

/**
 * URL加密
 *
 * @param URL 需要加密的URL
 * @param formData 表单数据
 *
 * @return 加密后的URL
 * @deprecated 算法已下线
 */
- (NSURL *)sgm_encryptURLWithURL:(NSURL *)URL formData:(nullable NSDictionary *)formData __attribute((deprecated));

/**
 * 更新时间戳，防止由于时间戳不匹配造成的请求失败
 * @serverTime 接口返回的正确时间戳，单位ms
 */
- (void)sgm_adjustWithServerTime:(long long)serverTime;

/**
 * 对bodyMD5Hex+deviceID+ts加签，不要在意名字
 * 原始数据格式：bodyMD5Hex_deviceID_ts
 * @param bodyMD5Hex post请求body的MD5 HEXString
 * @return 加签后的hexStr，拼接到请求里
 * @description 如果接入方自己做服务，那参数传什么都可以
 */
- (NSString *)testMsgLog:(NSString *)bodyMD5Hex;

/**
 * 自制加密接口
 * @param originStr 待加密内容
 * @return 加签后的hexStr
 */
- (NSString *)testMsgLog_Ori:(NSString *)originStr;

@end

@interface SGMSafeGuardManager (Verification)

/**
 * 调起验证码服务，会根据验证类型在当前页面弹出验证码控件，控件会遮盖整个屏幕，无法进行其他操作
 * @param scene 用于表示当前验证场景
 * @param type 表示验证码类型，例如点选、滑动
 * @param languageCode 语言类型，例如 zh-Hant\en\de；如不传会尝试使用系统首选语言顺序中首个支持的语言
 * @param presentingView 展示验证码的view，如有横竖屏切换场景请确保presentingView支持；如不传会创建一个window用于展示，该window支持横竖屏
 * @param callback 验证回调，当验证成功后，接入方需要进行二次验证
 */
- (void)sgm_popupVerificationViewOfScene:(NSString *)scene type:(SGMVerifyType)type languageCode:(nullable NSString *)languageCode presentingView:(nullable UIView *)presentingView callback:(SGMVerificationCallback)callback;

@end

/**
 * 新接入业务请不要调用以下方法
 */
@interface SGMSafeGuardManager (Deprecated)

// CFB
- (NSString *)sgm_deprecated_encryptString:(NSString *)originalString;
- (NSString *)sgm_deprecated_decryptString:(NSString *)decryptedString;

// CFB8
- (NSString *)sgm_deprecated_encryptString_cfb8:(NSString *)originalString;
- (NSString *)sgm_deprecated_decryptString_cfb8:(NSString *)decryptedString;

@end

NS_ASSUME_NONNULL_END
