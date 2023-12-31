//
//  SGMSafeGuardConfig.h
//  IESSafeGuard
//
//  Created by renfeng.zhang on 2018/1/31.
//

#import <Foundation/Foundation.h>
#import "SGMPreMacros.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct SGM_LocationCoordinate2D {
    double latitude;
    double longitude;
} SGM_LocationCoordinate2D;

@protocol SGMSafeGuardConfigDelegate <NSObject>

@optional

- (BOOL)isUseTTNet;

@end

@protocol SGMSafeGuardDelegate <SGMSafeGuardConfigDelegate>

@required

/* did */
- (NSString *)sgm_customDeviceID;
/* session id */
- (NSString *)sgm_sessionID;
/* install channel */
- (NSString *)sgm_installChannel;

- (void) sgm_sectoken:(NSString*)token;

@optional
/* 返回经纬度结构体 */
- (SGM_LocationCoordinate2D)sgm_currentLocation;
/* iid */
- (NSString *)sgm_installID;
/* 自定义内容，为了方便查询，请确保Dic是扁平无嵌套的 */
- (NSDictionary <NSString *, NSObject *>*)sgm_customInfoDic;
/* 是否需要手动控制指纹信息采集，若传YES请手动调用开始采集方法 */
- (BOOL)sgm_needConfigSelas;

@end //SGMSafeGuardDelegate

@interface SGMSafeGuardConfig : NSObject

/**
 *
 *  初始化配置信息
 *
 *  platform和secretkey用于旧签名，新签名不需设置
 *
 *  @param platform 接入平台，例如火山、抖音
 *  @param appID 接入app唯一标识
 *  @param hostType 用来判断host区域
 *  @param secretKey 用于请求验证
 *
 */
+ (instancetype)configWithPlatform:(SGMSafeGuardPlatform)platform
                             appID:(NSString *)appID
                          hostType:(SGMSafeGuardHostType)hostType
                         secretKey:(nullable NSString *)secretKey __attribute((deprecated));

+ (instancetype)configWithAppID:(NSString *)appID
                       hostType:(SGMSafeGuardHostType)hostType;

+ (instancetype)configWithDomain:(NSString *)domain
                           appID:(NSString *)appID;

@end //SGMSafeGuardConfig

NS_ASSUME_NONNULL_END
