//
//  TTSmallAppConfig.m
//  TTRexxar
//
//  Created by muhuai on 2017/11/17.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "BDPAppConfig.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPApplicationManager.h>
#import "BDPWindowConfig.h"

#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPSDK/OPSDK-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

NSString *const BDPAuthorizeDescriptionKeyUserInfo = @"userInfo";
NSString *const BDPAuthorizeDescriptionKeyUserLocation = @"userLocation";
NSString *const BDPAuthorizeDescriptionKeyAddress = @"address";
NSString *const BDPAuthorizeDescriptionKeyRecord = @"record";
NSString *const BDPAuthorizeDescriptionKeyAlbum = @"album";
NSString *const BDPAuthorizeDescriptionKeyCamera = @"camera";
NSString *const BDPAuthorizeDescriptionKeyPhoneNumber = @"phoneNumber";

@interface BDPAppConfig()

@property (nonatomic, strong) NSString *deviceOrientation;
/// app-config中的原始数据
@property (nonatomic, copy) NSDictionary<NSString *, BDPPageConfig *> *page;
/// 融合过window全局样式的pageConfig
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDPPageConfig *> *finalPageConfigs;
/// 无 tab 能力（强制禁止 tabBar 配置生效，比如应用于嵌入式Tab小程序）
@property (nonatomic, assign) BOOL noTab;

// Dark Mode 相关属性
@property (nonatomic, strong, nullable) BDPWindowThemeConfig<Optional> *windowDark;
@property (nonatomic, strong, nullable) BDPWindowConfig<Optional> *windowLight; // 保留一份不会被篡改的原始配置
@property (nonatomic, strong, nullable) BDPTabBarThemeConfig<Optional> *tabBarDark;
@property (nonatomic, strong, nullable) BDPTabBarConfig<Optional> *tabBarLight; // 保留一份不会被篡染的原始配置
@property (nonatomic, copy, nullable) NSDictionary<Optional> *pageTheme;

@end

@implementation BDPAppConfig

- (instancetype)initWithDict:(NSDictionary *)dict noTab:(BOOL)noTab {
    
    // 注入测试数据
//    NSMutableDictionary *nDic = dict.mutableCopy;
//    NSMutableDictionary * global = [nDic bdp_dictionaryValueForKey:@"global"].mutableCopy;
//
//    NSMutableDictionary * window = [global bdp_dictionaryValueForKey:@"window"].mutableCopy;
//    window[@"backgroundTextStyle"] = nil;
//    window[@"navigationBarBackgroundColor"] = nil;
//    window[@"navigationBarTextStyle"] = nil;
//    window[@"backgroundColor"] = nil;
//    window[@"transparentTitle"] = @"auto";  // 测试自动模式
//    global[@"window"] = window;
//    nDic[@"global"] = global;
//
//    NSMutableDictionary * tabBar = [nDic bdp_dictionaryValueForKey:@"tabBar"].mutableCopy;
//    tabBar[@"backgroundColor"] = nil;
//    tabBar[@"borderStyle"] = nil;
//    tabBar[@"color"] = nil;
//    nDic[@"tabBar"] = tabBar;
    
//    nDic[@"darkmode"] = @(true);
//    nDic[@"theme"] = @{
//        @"global": @{
//            @"window": @{
//                @"dark": @{
//                    @"backgroundTextStyle": @"light",
//                    @"navigationBarBackgroundColor": @"#FF0000",
//                    @"navigationBarTextStyle": @"white",
//                    @"backgroundColor": @"#00FF00"
//                }
//            }
//        }
//        ,
//        @"page": @{
//            @"page/API/index": @{
//                @"window": @{
//                    @"dark": @{
//                        @"backgroundTextStyle": @"light",
//                        @"navigationBarBackgroundColor": @"#0000FF",
//                        @"navigationBarTextStyle": @"white",
//                        @"backgroundColor": @"#00FF00"
//                    }
//                }
//            }
//        }
//        ,
//        @"tabBar": @{
//            @"dark": @{
//                @"color": @"#FFFFFF",
//                @"selectedColor": @"#00FF00",
//                @"backgroundColor": @"#FF0000",
//                @"borderStyle": @"white",
//                @"list": @[
//                    @{
//                        @"iconPath": @"image/cuvette.png",
//                        @"selectedIconPath": @"image/cuvette_HL.png"
//                    },
//                    @{
//                        @"iconPath": @"image/experiment.png",
//                        @"selectedIconPath": @"image/experiment_HL.png"
//                    }
//                ]
//            }
//        }
//    };
//    dict = nDic.copy;
    
    self = [self initWithDictionary:dict error:nil];
    if (self) {
        [self.window mergeExtendIfNeeded];
        self.noTab = noTab;
        
        // pageConfig的解析已经改成懒加载了, 如果要加什么特殊处理, 前往`getPageConfigByPath:`方法
        
        // TODO zhangchaojie 使用 global.networkTimeout 初始化
        if (!self.networkTimeout) {
            self.networkTimeout = [[BDPNetworkTimeoutConfig alloc] init];
        }
        
        // 初始化 Theme 相关的配置
        if(self.darkmode) {
            [self bindThemeConfig];
            [self applyDarkMode:OPIsDarkMode()];
        } else {
            BDPLogInfo(@"gadget config not support dark mode");
        }
    }
    return self;
}

- (void)dealloc
{
    BDPDebugNSLog(@"TMAAppConfig dealloc");
}

- (BOOL)containsPage:(NSString *)page
{
    BOOL contains = [self.pages containsObject:page];
    if (contains) {
        return contains;
    }
    //没取到的话做一次兼容, 有时有.html 有时没有.
    page = [page hasSuffix:@".html"]? [page componentsSeparatedByString:@".html"].firstObject: [page stringByAppendingString:@".html"];
    
    contains = [self.pages containsObject:page];
    return contains;
}

- (BOOL)isTabPage:(NSString *)page
{
    NSString *fixPage = [page hasSuffix:@".html"]? [page componentsSeparatedByString:@".html"].firstObject: [page stringByAppendingString:@".html"];
    for (BDPTabBarPageConfig *pageConfig in self.tabBar.list) {
        if ([page isEqualToString:pageConfig.pagePath] || [fixPage isEqualToString:pageConfig.pagePath]) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)tabBarIndexOfPath:(NSString *)path
{
    NSString *fixPage = [path hasSuffix:@".html"]? [path componentsSeparatedByString:@".html"].firstObject: [path stringByAppendingString:@".html"];
    for (NSInteger i = 0; i < self.tabBar.list.count; i++) {
        NSString *pagePath = self.tabBar.list[i].pagePath;
        if ([path isEqualToString:pagePath] || [fixPage isEqualToString:pagePath]) {
            return i;
        }
    }
    return NSNotFound;
}

- (BDPTabBarConfig<Optional> *)tabBar {
    if (_noTab) {
        // 无 tab 能力（强制禁止 tabBar 配置生效，比如应用于嵌入式Tab小程序）
        // 该配置项直接屏蔽
        return nil;
    }
    return _tabBar;
}

#pragma mark - PageConfig
- (BDPPageConfig *)getPageConfigByPath:(NSString *)path
{
    if (!path.length) {
        return nil;
    }
    BDPPageConfig *pageConfig = nil;
    @synchronized (self) {
        pageConfig = [self.finalPageConfigs objectForKey:path];
        if (!pageConfig) { // 第一道判断final字典中有无
            pageConfig = self.page[path];
            // 处理原始数据
            if (pageConfig) {
                BDPPageConfig *config = [[BDPPageConfig alloc] init];
                config.window = self.window;
                NSDictionary *windowDic = ((NSDictionary *)pageConfig)[@"window"];
                [config.window mergeFromDictionary:windowDic useKeyMapping:YES error:nil];
                //这里对originWindow也同步一份最page.json里window的备份
                config.originWindow = [[BDPWindowConfig alloc] init];
                [config.originWindow mergeFromDictionary:windowDic useKeyMapping:YES error:nil];
                NSString *appName = [[BDPApplicationManager sharedManager].applicationInfo bdp_stringValueForKey:BDPAppNameKey];
                config.window.extends = [[windowDic bdp_dictionaryValueForKey:@"extend"] bdp_dictionaryValueForKey:appName];
                [config.window mergeExtendIfNeeded];
                pageConfig = config;
                [self applyThemeConfigForPageConfig:pageConfig path:path];
                self.finalPageConfigs[path] = pageConfig;
            }
        }
        if (!pageConfig) {
            pageConfig = [[BDPPageConfig alloc] init];
            pageConfig.window = self.window;
            [self applyThemeConfigForPageConfig:pageConfig path:path];
            self.finalPageConfigs[path] = pageConfig;
        }
    }
    return pageConfig;
}

- (NSMutableDictionary<NSString *,BDPPageConfig *> *)finalPageConfigs {
    if (!_finalPageConfigs) {
        _finalPageConfigs = [[NSMutableDictionary<NSString *,BDPPageConfig *> alloc] init];
    }
    return _finalPageConfigs;
}

#pragma mark - JSONModel
+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    if ([propertyName isEqualToString:@"debug"]) {
        return YES;
    }
    return YES;
}

+ (JSONKeyMapper *)keyMapper
{
    NSDictionary *dict = @{@"window": @"global.window",
                           @"navigateToAppIdList": BDP_STRING_CONCAT(@"navigateToMiniP", @"rogramAppIdList"),  // navigateToMiniProgramAppIdList
                           @"launchApp": @"ttLaunchApp",
                           @"windowDark": @"theme.global.window.dark",
                           @"windowLight": @"global.window",
                           @"tabBarDark": @"theme.tabBar.dark",
                           @"tabBarLight": @"tabBar",
                           @"pageTheme": @"theme.page"
                           };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    return [super propertyIsIgnored:propertyName];
}

- (void)bindThemeConfig {
    if(!self.darkmode) {
        return;
    }
    
    if (!self.window) {
        BDPLogWarn(@"window is nil");
        // 如果存在一些情况 window 为空，也应当创建一个默认对象来承载 dark mode 数据。
        self.window = [[BDPWindowConfig alloc] init];
    }
    
    BDPLogInfo(@"bind theme config. windowDark:%@, windowLight:%@, tabBarDark:%@, tabBarLight:%@", self.windowDark, self.windowLight, self.tabBarDark, self.tabBarLight);
    
    [self.window bindThemeConfigWithDark:self.windowDark
                                   light:self.windowLight
                                pageDark:nil
                               pageLight:nil];
    
    [self.tabBar bindThemeConfigWithDark:self.tabBarDark
                                   light:self.tabBarLight];
}

- (void)applyDarkMode:(BOOL)darkMode {
    if(!self.darkmode) {
        return;
    }
    
    BDPLogInfo(@"applyDarkMode:%@", @(darkMode));
    
    [self.window applyDarkMode:darkMode];
    [self.tabBar applyDarkMode:darkMode];
    
    @synchronized (self) {
        [self.finalPageConfigs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, BDPPageConfig * _Nonnull obj, BOOL * _Nonnull stop) {
            [obj applyDarkMode:darkMode];
        }];
    }
}

- (void)applyThemeConfigForPageConfig:(BDPPageConfig *)pageConfig path:(NSString *)path {
    if(!self.darkmode) {
        return;
    }
    
    NSDictionary *pageDarkDic = [[[self.pageTheme bdp_dictionaryValueForKey:path] bdp_dictionaryValueForKey:@"window"] bdp_dictionaryValueForKey:@"dark"];
    NSError *error = nil;
    BDPWindowThemeConfig *pageDark = pageDarkDic ? [[BDPWindowThemeConfig alloc] initWithDictionary:pageDarkDic error:&error] : nil;
    if (error) {
        BDPLogError(@"parse pageDark failed. path:%@, error:%@", path, error);
    }
    
    error = nil;
    NSDictionary *pageLightDic = [[self.page bdp_dictionaryValueForKey:path] bdp_dictionaryValueForKey:@"window"];
    BDPWindowThemeConfig *pageLight = pageLightDic ? [[BDPWindowThemeConfig alloc] initWithDictionary:pageLightDic error:&error] : nil;
    if (error) {
        BDPLogError(@"parse pageLight failed. path:%@, error:%@", path, error);
    }
    BDPLogInfo(@"bind page theme config. path:%@, pageDark:%@, pageLight:%@", path, pageDarkDic, pageLightDic);
    [pageConfig bindThemeConfigWithDark:self.windowDark
                                  light:self.windowLight
                               pageDark:pageDark
                              pageLight:pageLight];
    [pageConfig applyDarkMode:OPIsDarkMode()];
}

- (NSString * _Nullable)redirectPage:(NSString *)page
{
    for (NSInteger i = 0; i < self.redirectPagePath.count; i++) {
        BDPRedirectPageConfig *redirectPageConfig = self.redirectPagePath[i];
        if ([redirectPageConfig.fromPath isEqualToString:page] && [self.pages containsObject:redirectPageConfig.toPath]) {
            return redirectPageConfig.toPath;
        }
    }
    return nil;
}

@end

