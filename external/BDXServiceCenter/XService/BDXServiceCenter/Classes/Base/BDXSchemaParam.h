//
//  BDXSchemaParam.h
//  BDXServiceCenter
//
//  Created by bytedance on 2021/3/17.
//  Schema参数标准定义
//  https://roma.bytedance.net/pattern_detail/?appId=990003&patternId=2865

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXSchemaParam : NSObject

#pragma mark - UI

//状态栏图标light/dark模式
@property(nonatomic, assign) UIStatusBarStyle statusFontMode;
//状态栏背景颜色
@property(nonatomic, strong) UIColor *statusBarColor;
//加载时是否显示loading页
@property(nonatomic, assign) BOOL showLoading;
//加载失败时显示错误页
@property(nonatomic, assign) BOOL showError;
//容器背景色（十六进制rgba）
@property(nonatomic, strong) UIColor *containerBgColor;
//加载时候的容器背景色（十六进制rgba）
@property(nonatomic, strong) UIColor *loadingBgColor;

#pragma mark - ability

//是否禁用内置资源
@property(nonatomic, assign) NSNumber *disableBuiltIn;
//是否禁用Gecko资源
@property(nonatomic, assign) NSNumber *disableGurd;

#pragma mark - common

// query参数全集
@property(nonatomic, strong) NSDictionary *extra;
//加载的原始URL
@property(nonatomic, strong) NSURL *originURL;
//转换后的URL
@property(nonatomic, strong) NSURL *resolvedURL;
//加载失败的兜底加载URL
@property(nonatomic, copy) NSString *fallbackURL;
//是否强制fallback到H5
@property(nonatomic, strong) NSNumber *forceH5;

/// 根据字典生成 BDXSchemaParam
+ (instancetype)paramWithDictionary:(NSDictionary *)dictionary;

/// 根据新的 param 更新现有 param
- (void)updateWithParam:(BDXSchemaParam *)newParam;

/// 根据dictionary 更新现有 param
- (void)updateWithDictionary:(NSDictionary *)dict;

@end

@protocol BDXPageSchemaParamProtocol

@required

//导航栏显示隐藏控制
@property(nonatomic, assign) BOOL hideNavBar;
// 状态栏显示隐藏控制
@property(nonatomic, assign) BOOL hideStatusBar;
//导航栏标题
@property(nonatomic, copy) NSString *title;
//导航栏标题字体颜色
@property(nonatomic, strong) UIColor *titleColor;
//导航栏背景颜色
@property(nonatomic, strong) UIColor *navBarColor;
//是否全屏(会展示状态栏图标)
@property(nonatomic, assign) BOOL transStatusBar;
/// 是否禁止右滑退出页面，默认为NO
@property(nonatomic, assign) BOOL disableSwipe;

@end

@protocol BDXPopupSchemaParamProtocol

@end

NS_ASSUME_NONNULL_END
