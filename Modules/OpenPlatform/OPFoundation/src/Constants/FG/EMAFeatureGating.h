//
//  EMAFeatureGating.h
//  Pods
//
//  Created by houjihu on 2019/5/30.
//

#import <Foundation/Foundation.h>
#import <ECOInfra/EMAFeatureGating.h>

/// ⚠️⚠️⚠️：这里新增key之后，必须在Lark内的FeatureGatingKey新增对应的枚举值（value与此处key对应的value一致），否则在配置取不到对应的值
/// 设置小程序引擎网络代理是否走Rust SDK
extern NSString *const EMAFeatureGatingKeyMicroAppNetworkRust;
/// 是否开启 reportAnalytics 接口
extern NSString *const EMAFeatureGatingKeyMicroAppReportAnalytics;
/// AppLink 是否使用自定义的domain（使用在EMAAppLinkModel中，目前用于小程序卡片分享）
extern NSString *const EMAFeatureGatingKeyMicroAppAppLinkCustomDomain;
/// Diagnose API 灰度控制
extern NSString *const EMAFeatureGatingKeyMicroAppDiagnoseApiEnable;
