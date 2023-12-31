//
//  CJPayWebviewStyle.m
//  CJPay
//
//  Created by 尚怀军 on 2019/7/22.
//

#import "CJPayWebviewStyle.h"

#import "CJPayUIMacro.h"


@interface CJPayWebviewStyle ()

@property (nonatomic, assign, readwrite) BOOL usesCustomStatusBarStyle;
@property (nonatomic, assign, readwrite) UIStatusBarStyle customStatusBarStyle;
@property (nonatomic, assign, readwrite) CJPayBackButtonStyle backButtonStyle;
@property (nonatomic, copy, readwrite) NSString *showsLoadingStr;

@end

@implementation CJPayWebviewStyle
/*
 schema中端能力key定义如下：
 container_bcg_color        webview外层容器的背景色/安卓端对应参数为background_color
 webview_bcg_color          webview背景色/H5无该参数
 back_button_color          返回按钮颜色
 hide_navigation_bar        是否隐藏导航栏
 hide_back_button           是否隐藏返回按钮
 title                      导航栏标题
 need_full_screen           是否需要全屏,全屏webview顶到屏幕顶端，非全屏有导航栏webview顶部顶到
                            导航条下方，非全屏无导航栏webview顶部顶到状态栏下方
 bounce_enable              是否需要bounce
 need_landscape             是否需要横屏
 fullpage                   0:竖半屏  1:竖全屏  2：横半屏
 canvas_mode                画布模式，画布模式下，隐藏状态栏布局、隐藏标题栏布局、隐藏返回按钮、显示状态栏文字
 */

#pragma mark - JSONModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"statusBarColor" : @"status_bar_color",
                @"containerBcgColor": @"container_bcg_color",
                @"webBcgColor": @"webview_bcg_color",
                
                @"titleText": @"title",
                @"navbarTitleColor": @"title_text_color",
                @"navbarBackgroundColor": @"title_bar_bg_color",
                @"hidesNavbar": @"hide_title_bar",
//                @"hidesNavbar": @"hide_navigation_bar",

                @"backButtonColor": @"back_button_color",
                @"backButtonStyle": @"back_button_icon",
                @"hidesBackButton": @"hide_back_button",

                @"hidesStatusBar": @"hide_status_bar",
                @"statusBarTextStyleString": @"status_bar_text_style",
                
                @"needFullScreen": @"need_full_screen",
                @"bounceEnable": @"bounce_enable",
                @"isLandScape": @"need_landscape",
                
                @"disablePopGesture": @"cj_disable_close",
                @"isCaijingSaas": @"is_caijing_saas",
                @"closeWebviewTimeout": @"cj_timeout",
                @"secLinkScene": @"secLinkScene",
                @"canvasMode" : @"canvas_mode",
                @"showsLoadingStr" : @"show_loading",
                @"cjCustomUserAgent" : @"cj_custom_ua",
                @"enableFontScale": @"enable_font_scale",
                @"openMethod" : @"open_method",
                @"postData" : @"post_form_data",
                @"bankSign" : @"bank_sign",
                @"bankName" : @"bank_name",
                @"returnUrl" : @"return_url",
                @"disableHistory" : @"disable_history"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

#pragma mark - Public

- (instancetype)init {
    self = [super init];
    if (self) {
        // 设置webview默认样式
        [self p_setDefaultWebviewStyle];
    }
    return self;
}

- (void)setStatusBarTextStyleString:(NSString *)statusBarTextStyleString
{
    if ([statusBarTextStyleString length] == 0) {
        return;
    }
    
    if (![statusBarTextStyleString isEqualToString:@"light"]
        && ![statusBarTextStyleString isEqualToString:@"dark"]) {
        return;
    }
    
    _statusBarTextStyleString = [statusBarTextStyleString copy];
    _usesCustomStatusBarStyle = YES;
    if ([_statusBarTextStyleString isEqualToString:@"dark"]) {
        _customStatusBarStyle = UIStatusBarStyleLightContent;
    }
}

- (void)setBackButtonStyleWithNSString:(NSString *)string
{
    if ([string isEqualToString:@"close"]) {
        _backButtonStyle = kCJPayBackButtonStyleClose;
    } else {
        _backButtonStyle = kCJPayBackButtonStyleArrow;
    }
}

- (NSString *)JSONObjectForBackButtonStyle
{
    switch (self.backButtonStyle) {
        case kCJPayBackButtonStyleClose:
            return @"close";
        case kCJPayBackButtonStyleArrow:
            return @"arrow";
        default:
            return @"arrow";
    }
}

- (BOOL)showsLoading {
    if (Check_ValidString(self.showsLoadingStr) && [self.showsLoadingStr isEqualToString:@"2"]) {
        return NO;
    }
    return YES;
}

#pragma mark - Private

- (void)p_setDefaultWebviewStyle {
    // 设置一组webview的兜底样式
    self.containerBcgColor = [UIColor whiteColor];
    self.webBcgColor = [UIColor whiteColor];
    self.backButtonColor = [UIColor blackColor];
    self.statusBarColor = [UIColor clearColor];
    self.hidesNavbar = NO;
    self.hidesBackButton = NO;
    self.needFullScreen = NO;
    self.bounceEnable = YES;
    self.isLandScape = NO;
    self.canvasMode = NO;
    self.disablePopGesture = NO;
    self.isCaijingSaas = NO;
    self.closeWebviewTimeout = 0;
    self.navbarBackgroundColor = [UIColor whiteColor];
    _hidesStatusBar = NO;
    _statusBarTextStyleString = @"light";
    _customStatusBarStyle = UIStatusBarStyleDefault;
    _backButtonStyle = kCJPayBackButtonStyleArrow;
}

- (void)amendByDic:(NSDictionary *)params
{
    if (params.count == 0) {
        return;
    }
    
    NSError *error = nil;
    [self mergeFromDictionary:params useKeyMapping:YES error:&error];
    if (error) {
        CJPayLogInfo(@"CJPayWebviewStyle p_amendByDic json error: %@", error);
    }
}

- (void)amendByUrlString:(NSString *)urlString {
    NSDictionary *params = [urlString cj_urlQueryParams];
    [self amendByDic:params];
}

- (BOOL)isNeedFullyTransparent {
    return self.containerBcgColor == [UIColor clearColor]
            && self.webBcgColor == [UIColor clearColor];
}

- (BOOL)needAppendCommonQueryParams {
//    一键绑卡不需要拼接公共参数，而一键绑卡是走PostData传输数据的，此种情况下直接返回
    BOOL isQuickBindCard = Check_ValidString(self.postData) && [[self.openMethod uppercaseString] isEqualToString:@"POST"];
    return !isQuickBindCard;
}

#pragma mark - getter & setter

- (void)setWebBcgColor:(UIColor *)webBcgColor {
    if (webBcgColor) {
        _webBcgColor = webBcgColor;
    }
}

- (void)setContainerBcgColor:(UIColor *)containerBcgColor {
    if (containerBcgColor) {
        _containerBcgColor = containerBcgColor;
    }
}

- (BOOL)hidesNavbar {
    if (_canvasMode) {
        // 隐藏标题栏
        return YES;
    } else {
        return _hidesNavbar;
    }
}

- (BOOL)hidesBackButton {
    if (_canvasMode) {
        // 隐藏返回按钮
        return YES;
    } else {
        return _hidesBackButton;
    }
}

- (BOOL)hidesStatusBar {
    if (_canvasMode) {
        // 隐藏状态栏
        return YES;
    } else {
        return _hidesStatusBar;
    }
}

- (NSString *)titleText {
    if ([_titleText rangeOfString:@"%"].length == 0) {
        return _titleText;
    } else {
        return [_titleText stringByRemovingPercentEncoding];
    }
}

@end
