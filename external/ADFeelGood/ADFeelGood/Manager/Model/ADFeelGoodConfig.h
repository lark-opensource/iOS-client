//
//  ADFeelGoodConfig.h
//  ADFeelGoodSDK
//
//  Created by bytedance on 2020/9/4.
//  Copyright © 2020 huangyuanqing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 全局配置模型
@interface ADFeelGoodConfig : NSObject

/// 业务密钥
@property (nonatomic, copy, nonnull) NSString *appKey;
/// 设备id
@property (nonatomic, copy, nonnull) NSString *did;
/// 用户id
@property (nonatomic, copy, nonnull) NSString *uid;
/// 用户名称
@property (nonatomic, copy, nonnull) NSString *uName;
/// cn/va 中国区/非中国区
@property (nonatomic, copy, nonnull) NSString *channel;
/// 语言地区 zh_CN
@property (nonatomic, copy, nonnull) NSString *language;
/// 设备类型： 手机mobile/平板tablet
@property (nonatomic, copy, nonnull) NSString *deviceType;
// 添加通用userInfo，请求时传入user字段中
@property (nonatomic, copy, nullable) NSDictionary *userInfo;

@end

NS_ASSUME_NONNULL_END
