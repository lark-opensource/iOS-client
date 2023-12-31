//
//  HMDTTMonitorUserInfo.h
//  Heimdallr
//
//  Created by 王佳乐 on 2018/10/29.
//

#import <Foundation/Foundation.h>

typedef NSString * _Nullable (^ _Nullable HMDTTMonitorURLTransformBlock)(NSString * _Nullable originalURLString);
typedef NSDictionary<NSString *, id> * _Nullable (^ _Nullable HMDTTMonitorCommonParamsBlock)(void);

@interface HMDTTMonitorUserInfo : NSObject

@property (nonatomic, copy, readonly, nonnull) NSString *appID;/**应用标示，如头条主端是13 */

@property (nonatomic, copy, nullable) NSString *hostAppID;/**宿主 AppID*/
@property (nonatomic, copy, nullable) NSString *deviceID;/**从TTInstallService库中获取到的设备标示 */
@property (nonatomic, copy, nullable) NSString *userID;/**用户ID，如果能取到的话就赋值*/
@property (nonatomic, copy, nullable) NSString *channel;/**应用渠道，正式包用App Store，内测版用local_test*/
@property (nonatomic, copy, nullable) NSString *sdkVersion;/**SDK version，默认为App的版本*/
@property (nonatomic, copy, nullable) HMDTTMonitorURLTransformBlock transformBlock;/**对上报或者配置URL加工，如修改域名 */
@property (atomic, copy, nullable) HMDTTMonitorCommonParamsBlock commonParamsBlock;/**通用参数 动态，异步，可优化启动时间*/
@property (atomic, copy, nullable) NSDictionary<NSString*, id> *commonParams;/**上报接口中的query参数 */
@property (nonatomic, copy, nullable) NSArray *configHostArray;/** 配置拉取和重试域名*/
@property (nonatomic, copy, nullable) NSString *performanceUploadHost;/** CPU 等性能数据上报域名*/
@property (nonatomic, assign) NSUInteger flushCount;/** 内存中日志写入数据库的阈值 */
@property (nonatomic, assign) BOOL enableBackgroundUpload;/** 是否允许SDKMonitor在App退后台时主动上报日志，默认NO*/
@property (nonatomic, copy, nullable) NSDictionary<NSString*, id> *customHeader; /**用户自定义header字段*/

// compliance
@property (nonatomic, copy, nullable) NSString *scopedDeviceID;/**  */
@property (nonatomic, copy, nullable) NSString *scopedUserID;/** */

- (nonnull instancetype)initWithAppID:(nonnull NSString *)appID;
- (nonnull id)init __attribute__((unavailable("initWithAppID:")));
+ (nonnull instancetype)new __attribute__((unavailable("initWithAppID:")));

@end
