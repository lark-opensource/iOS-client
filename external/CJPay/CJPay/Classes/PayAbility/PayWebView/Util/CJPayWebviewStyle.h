//
//  CJPayWebviewStyle.h
//  CJPay
//
//  Created by 尚怀军 on 2019/7/22.
//

#import <JSONModel/JSONModel.h>

typedef enum : NSUInteger {
    kCJPayBackButtonStyleArrow = 0,
    kCJPayBackButtonStyleClose,
} CJPayBackButtonStyle;

NS_ASSUME_NONNULL_BEGIN

// 用于从schema中解析存储webview的样式，包括是否有导航条、背景色、返回按钮颜色等等
// 端能力参数可以拼接在url后边如http://XXXXXXX?hide_navigation_bar=1
// 端能力参数也可以拼接在schema后边如cjpay://webview?hide_navigation_bar=1&url=http://XXXXXXX
// 推荐后一种写法，这种写法端能力参数和url处于同一级，端能力参数定制webview样式，url确定webview内容
@interface CJPayWebviewStyle : JSONModel

//原子属性
@property (nonatomic, strong, nullable) UIColor *statusBarColor;
@property (nonatomic, strong, nullable) UIColor *containerBcgColor;
@property (nonatomic, strong, nullable) UIColor *webBcgColor;
// NavigationBar相关
@property (nonatomic, assign) BOOL hidesNavbar; // 是否隐藏导航条
@property (nonatomic, assign) BOOL hidesBackButton; // 是否隐藏返回箭头。iOS实现相关：hidesNavbar只隐藏导航条，还有backbutton
@property (nonatomic, strong, nullable) UIColor *navbarBackgroundColor; // 导航条背景色
@property (nonatomic, strong, nullable) UIColor *navbarTitleColor; // 导航条文字颜色
@property (nonatomic, copy) NSString *titleText;

@property (nonatomic, strong, nullable) UIColor *backButtonColor; // 设置返回按钮的背景色
//@property (nonatomic, copy, nullable) NSString *backButtonStyleString; // 设置返回按钮的样式参数值
@property (nonatomic, assign, readonly) CJPayBackButtonStyle backButtonStyle; // 设置返回按钮的样式

// StatusBar相关，其中statusBarTextStyleString为H5传递的参数
// usesCustomStatusBarStyle和customStatusBarStyle为计算属性
@property (nonatomic, assign) BOOL hidesStatusBar; // 是否隐藏状态栏。
@property (nonatomic, copy, nullable) NSString *statusBarTextStyleString; // H5给的状态栏文字颜色的属性，light:黑色，dark:白色，默认是light
@property (nonatomic, assign, readonly) BOOL usesCustomStatusBarStyle;
@property (nonatomic, assign, readonly) UIStatusBarStyle customStatusBarStyle;

@property (nonatomic, assign) BOOL needFullScreen;
@property (nonatomic, assign) BOOL bounceEnable;
@property (nonatomic, assign) BOOL isLandScape;
@property (nonatomic, assign, readonly) BOOL showsLoading; //0 是默认 1是显示 2是不显示

// 画布模式，该模式下
// 1. 隐藏状态栏布局
// 2. 隐藏标题栏布局
// 3. 隐藏返回按钮
// 4. 显示状态栏文字（可控字体颜色）
@property (nonatomic, assign) BOOL canvasMode;

@property (nonatomic, assign) BOOL disablePopGesture;
@property (nonatomic, assign) BOOL isCaijingSaas; // 是否处于SaaS环境（是则需要在网络请求header增加accessToken）
@property (nonatomic, assign) NSInteger closeWebviewTimeout;

@property (nonatomic, copy) NSString *secLinkScene; // 打开Webview的来源，目前用于secLink处理
@property (nonatomic, copy) NSString *cjCustomUserAgent; // 自定义ua
@property (nonatomic, copy) NSString *enableFontScale;   // 前端控制是否启用大字模式

//聚合属性
@property(nonatomic, assign, readonly) BOOL isNeedFullyTransparent;
@property (nonatomic, assign, readonly) BOOL needAppendCommonQueryParams;


//绑卡安全感补充参数
@property (nonatomic, copy) NSString *openMethod;
@property (nonatomic, copy) NSString *postData;
@property (nonatomic, copy) NSString *bankSign;
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *returnUrl;
@property (nonatomic, copy) NSString *disableHistory;

- (void)amendByUrlString:(NSString *)urlString;
// 从字典里补充
- (void)amendByDic:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
