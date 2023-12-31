//
//  ADFeelGoodOpenModel.h
//  FeelGoodDemo
//
//  Created by cuikeyi on 2021/1/11.
//  Copyright © 2021 huangyuanqing. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ADFGOpenType) {
    ADFGOpenTypeNormal = 0, // addChildViewController的方式
    ADFGOpenTypeWindow = 1, // window层级，level = UIWindowLevelAlert + 1
};

typedef NS_ENUM(NSInteger, ADFGDarkModeType) {
    ADFGDarkModeTypeLight   = 0,    // 强制为浅色
    ADFGDarkModeTypeDark    = 1,    // 强制为深色
    ADFGDarkModeTypeSystem  = 2,    // 跟随系统darkmode
};

NS_ASSUME_NONNULL_BEGIN

/// 打开FeelGood页面配置模型
@interface ADFeelGoodOpenModel : NSObject

/// feelgood的打开方式，非必选，默认为ADFGOpenTypeNormal
@property (nonatomic, assign) ADFGOpenType openType;
/// 展示feelgood的页面
@property (nonatomic, weak) UIViewController *parentVC;
/// webview页面背景颜色
@property (nonatomic, strong, nullable) UIColor *bgColor;
/// 自定义用户标识，请求时添加到user字典中
@property (nonatomic, strong, nullable) NSDictionary *extraUserInfo;
/// 是否开启加载动画
@property (nonatomic, assign) BOOL needLoading;
/// 外部设置超时时间
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
/// 页面darkMode类型
@property (nonatomic, assign) ADFGDarkModeType darkModeType;

/// 全局展示模式  ipad适配
#ifdef __IPHONE_13_0
@property (nonatomic, weak) API_AVAILABLE(ios(13.0)) UIWindowScene *windowScene;
#endif

@end

NS_ASSUME_NONNULL_END
