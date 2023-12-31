//
//  BDLSDKProtocol.h
//  AFgzipRequestSerializer
//
//  Created by zys on 2020/2/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDLSDKProtocol <NSObject>

- (NSString *)lynxBusinessDomain;

/**
 *是否是第一次安装启动
 */
- (BOOL)isStartUpFirstTime;

/**
 *是否停止下载功能,审核期间不下载模板，宿主通过setting判断
 */
- (BOOL)disableDownloadTemplate;

- (NSString *)appVersion;

@optional

- (NSString *)
    lynxSettingsDomain DEPRECATED_MSG_ATTRIBUTE("Method deprecated! Refer to BDLConfig.m");
;

/**
 *向lynx view注册自定义组件，返回一个实现注册功能的block
 */
- (void (^)(void))registCustomUIComponent;

@end

NS_ASSUME_NONNULL_END
