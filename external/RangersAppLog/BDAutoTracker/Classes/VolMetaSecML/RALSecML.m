//
//  RALSecML.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/4/27.
//

#import "RALSecML.h"
#import "BDAutoTrackNotifications.h"
#import "BDAutoTrack.h"
#import "RangersAppLogConfig.h"


typedef NS_ENUM(NSInteger, _ClientType) {
    _ML_CLIENT_TYPE_UNKNOWN = -1,
    _ML_CLIENT_TYPE_INHOUSE = 0,
    _ML_CLIENT_TYPE_BUSINESS = 1
};


@interface MSConfigML : NSObject

+ (instancetype)new __attribute__((unavailable("please use [initWithAppID:License:] or [initWithSDKID:SubAppID:License:]")));
- (instancetype)init __attribute__((unavailable("please use [initWithAppID:License:] or [initWithSDKID:SubAppID:License:]")));

// MSConfigML配置初始化接口，app初始化使用该接口，license申请见操作文档 https://bytedance.feishu.cn/docs/doccny0YGd9wpqwRCvKdXSFJuag#
- (instancetype)initWithAppID: (NSString* _Nonnull)appID License:(NSString * _Nonnull)licenseStr;

// MSConfigML配置初始化接口，中台SDK初始化使用该接口，license申请见操作文档 https://bytedance.feishu.cn/docs/doccny0YGd9wpqwRCvKdXSFJuag#
- (instancetype)initWithSDKID: (NSString* _Nonnull)sdkID SubAppID:(NSString * _Nonnull)subAppID License:(NSString * _Nonnull)licenseStr;

//必填项:客户端类型枚举值，MS_ML_CLIENT_TYPE_INHOUSE（字节开发的app，字节的同学填这个）、MS_ML_CLIENT_TYPE_BUSINESS（字节的外部客户，其他公司开发的app）
- (MSConfigML *(^)( _ClientType))     setClientType;

 //慎重 必填项:deviceid、did，该接口既是设置did的接口，又是一个合规确认的接口。一旦调用并且传入的did有值，会delay xx 秒后触发设备信息采集。所以请先判断用户是否已经同意隐私协议，在用户确认隐私协议合规之前，此接口不可调用；在非新增设备上，用户如果已经同意了隐私协议，该接口必须要调用。
- (MSConfigML *(^)( NSString* _Nonnull ))setDeviceID;

//tob的必填项，字节内部的app不用理会
- (MSConfigML *(^)( NSString* _Nonnull ))setBDDeviceID;

//必填项:installid,如果新增设备初始化时没有获取到可以不填
- (MSConfigML *(^)( NSString* _Nonnull ))setInstallID;

//可选项，MSConfigML配置更改接口:idfa,不主动采集，如果业务方有采集或者idfa异步获取的，后续要求可以通过 MSManagerML 再次填入，并调用 reportForScence接口上报更改，有助于分析作弊case
- (MSConfigML *(^)( NSString* _Nonnull ))setIDFA;

//可选项:用户组件TTAccountSDK 生成的sessionid,非uid,当前uid登录时生成的session,如果初始化时没有获取到可以不设置该接口。但是后续用户有登入登出行为导致sessionid有更新，后续要求必须通过 MSManagerML 再次填入
- (MSConfigML *(^)( NSString* _Nonnull ))setSessionID;

//必填项:安装渠道
- (MSConfigML *(^)( NSString* _Nonnull ))setChannel;

/**
* @brief setCustomInfo()
*
* @param  dic a NSDictionary * that the key and the value must be NSString* ,otherwise other types will be blocked.
*
* @return MSConfigML *.
*/
- (MSConfigML *(^)( NSDictionary<NSString* , NSString*>* _Nonnull dic))setCustomInfo;
- (MSConfigML *(^)(NSString* _Nonnull key, NSString* _Nonnull val)) addAdvanceInfo;

@end

@interface MSManagerML : NSObject
- (instancetype)initWithConfig:(MSConfigML*)config;
- (MSManagerML *(^)( NSString* _Nonnull ))setBDDeviceID;
- (MSManagerML *(^)( NSString* _Nonnull ))setInstallID;
- (void)reportForScene:(NSString* _Nonnull)scene;
@end


static id s_msManager;

@implementation RALSecML

+ (id)getMSManager {
    return s_msManager;
}

+ (void)bootMSSecML {
    
    if ( NSClassFromString(@"MSConfigML")
        && NSClassFromString(@"MSManagerML") ) {
        
        Class MSConfigMLClass = NSClassFromString(@"MSConfigML");
        id config = [[MSConfigMLClass alloc] initWithSDKID:@"214304" SubAppID:[BDAutoTrack sharedTrack].appID License:@"j7NZkNoy1uwhWVvY/cjSDTpc4k354AaK972Mqwc0mt+lPdfsMix71pwSAIh/ZWlCsiL5qejU65L6XuWVUnVbhu2YAdaA2emNQWcig58GLNqniNLLsK5dp1L4D/0xwDXda9DwIbcDWAGiBzTQUFVcHg+73v27D7M4jOMM3WKXEgguPYAeeBfvkapserB8ss4mrlTIQJdKClcRAo4EFJNa4snOMxfHHom6DXlxaXcc0St5ZEIjlJkfjQqfEas+NcZrGV3A4w=="];
        
        
//        MSConfigML *msConfig = [[MSConfigML alloc] initWithSDKID:@"214304"  // 云安全平台申请的sdkID
//                                                        SubAppID:[BDAutoTrack sharedTrack].appID  // 业务方的appID
//                                                         License:@"j7NZkNoy1uwhWVvY/cjSDTpc4k354AaK972Mqwc0mt+lPdfsMix71pwSAIh/ZWlCsiL5qejU65L6XuWVUnVbhu2YAdaA2emNQWcig58GLNqniNLLsK5dp1L4D/0xwDXda9DwIbcDWAGiBzTQUFVcHg+73v27D7M4jOMM3WKXEgguPYAeeBfvkapserB8ss4mrlTIQJdKClcRAo4EFJNa4snOMxfHHom6DXlxaXcc0St5ZEIjlJkfjQqfEas+NcZrGV3A4w=="];
        
        id(^setTypeBlock)( _ClientType) = [config setClientType];
        if (setTypeBlock) {
            setTypeBlock(_ML_CLIENT_TYPE_BUSINESS);
        }
        
        id(^setChannelBlock)( NSString *) = [config setChannel];
        if (setChannelBlock) {
            setChannelBlock(@"App Store");
        }
        
        id(^setUniqueIDBlock)( NSString *) = [config setIDFA];
        NSString *uniqueID = [[RangersAppLogConfig sharedInstance].handler uniqueID];
        if (setUniqueIDBlock && [uniqueID length] > 1) {
            setUniqueIDBlock(uniqueID);
        }
    
        s_msManager = [[NSClassFromString(@"MSManagerML") alloc] initWithConfig:config];
      
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRegisterSuccess:) name:BDAutoTrackNotificationRegisterSuccess object:nil];
    }
    
}

/// 在注册成功后，补充或更新DeviceID和InstallID信息。
+ (void)onRegisterSuccess:(NSNotification *)noti {
    NSDictionary *userInfo = noti.userInfo;
    NSString *bddid = userInfo[kBDAutoTrackNotificationRangersDeviceID];
    NSString *iid = userInfo[kBDAutoTrackNotificationInstallID];
    if (s_msManager && bddid && iid && bddid.length && iid.length) {
        
        id(^setBDDeviceIDBlock)( NSString *) = [s_msManager setBDDeviceID];
        if (setBDDeviceIDBlock) {
            setBDDeviceIDBlock(bddid);
        }
        id(^setInstallIDBlock)( NSString *) = [s_msManager setInstallID];
        if (setInstallIDBlock) {
            setInstallIDBlock(iid);
        }
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (s_msManager && [s_msManager respondsToSelector:@selector(reportForScene:)]) {
                [s_msManager reportForScene:@"applog"];
            }
        });
        
//        ((MSManagerML *)s_msManager).setBDDeviceID(bddid).setInstallID(iid);
    }
}

@end
