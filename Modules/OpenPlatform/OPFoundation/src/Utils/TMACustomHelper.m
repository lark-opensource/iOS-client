//
//  TMAHelper.m
//  Timor
//
//  Created by CsoWhy on 2018/8/29.
//

#import "TMACustomHelper.h"
#import "BDPUtils.h"
#import "BDPTimorClient.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "BDPImageHelper.h"
#import "BDPResponderHelper.h"
#import "BDPDeviceHelper.h"
#import <OPFoundation/OPFoundation-Swift.h>

@implementation TMACustomHelper

+ (void)showCustomToast:(NSString *)content icon:(NSString *)icon window:(UIWindow * _Nullable)window
{
    id<BDPToastPluginDelegate> toastPlugin = (id<BDPToastPluginDelegate>)[[[BDPTimorClient sharedClient] toastPlugin] sharedPlugin];
    if ([toastPlugin respondsToSelector:@selector(bdp_showToastWithModel:)]) {
        BDPExecuteOnMainQueue(^{
            BDPToastPluginModel *model = [[BDPToastPluginModel alloc] init];
            model.title = content;
            model.icon = icon;
            [toastPlugin bdp_showToastWithModel:model];
        });
    }
}

+ (void)showCustomLoadingToast:(NSString *)content window:(UIWindow * _Nullable)window
{
    [self showCustomToast:content icon:@"loading" window:window];
}

+ (void)hideCustomLoadingToast:(UIWindow * _Nullable)window
{
    id<BDPToastPluginDelegate> toastPlugin = (id<BDPToastPluginDelegate>)[[[BDPTimorClient sharedClient] toastPlugin] sharedPlugin];
    if ([toastPlugin respondsToSelector:@selector(bdp_hideToast:)]) {
        BDPExecuteOnMainQueue(^{
            [toastPlugin bdp_hideToast:window];
        });
    }
}

+ (void)configNavigationController:(UIViewController *)currentViewController innerNavigationController:(UINavigationController *)innerNavigationController barHidden:(BOOL)isBarHidden dragBack:(BOOL)dragBack
{
    id<BDPNavigationPluginDelegate> naviPlugin = (id<BDPNavigationPluginDelegate>)[[[BDPTimorClient sharedClient] navigationPlugin] sharedPlugin];
    if ([naviPlugin respondsToSelector:@selector(bdp_configNavigationControllerWithParam:currentViewController:)]) {

        [naviPlugin bdp_configNavigationControllerWithParam:@{@"navigationBarHidden":@(isBarHidden),
                                                              @"navigationGestureBack":@(dragBack)}
                                      currentViewController:currentViewController];
    } else {
        [innerNavigationController setNavigationBarHidden:isBarHidden animated:YES];
    }
}

+ (BOOL)currentNavigationControllerHidden:(UIViewController *)currentViewController innerNavigationController:(UINavigationController *)innerNavigationController
{
    id<BDPNavigationPluginDelegate> naviPlugin = (id<BDPNavigationPluginDelegate>)[[[BDPTimorClient sharedClient] navigationPlugin] sharedPlugin];
    return [innerNavigationController isNavigationBarHidden];
}

+ (BOOL)isInTabBarController:(UIViewController *)appController
{
    BOOL isTabbarController = NO;
    UIViewController *rootNav = appController.navigationController.parentViewController;
    if ([rootNav isKindOfClass:[UITabBarController class]]) {
        isTabbarController = YES;
    }
    return isTabbarController;
}

//+ (NSDictionary *)queryParamsForURL:(NSURL *)URL
//{
//    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
//
//    NSRange schemeSegRange = [URL.absoluteString rangeOfString:@"://"];
//    NSString *outScheme = nil;
//    if (schemeSegRange.location != NSNotFound) {
//        outScheme = [URL.absoluteString substringFromIndex:NSMaxRange(schemeSegRange)];
//    } else {
//        outScheme = URL.absoluteString;
//    }
//
//    NSArray *substrings = [outScheme componentsSeparatedByString:@"?"];
//    NSString *firstString = [substrings firstObject];
//    if ([substrings count] > 1) {
//        NSString *queryString = [outScheme substringFromIndex:(firstString.length + 1)];
//        NSArray *paramsList = [queryString componentsSeparatedByString:@"&"];
//        [paramsList enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL *stop) {
//            NSArray *keyAndValue = [param componentsSeparatedByString:@"="];
//            if ([keyAndValue count] > 1) {
//                NSString *paramKey = [keyAndValue objectAtIndex:0];
//                NSString *paramValue = [keyAndValue objectAtIndex:1];
//                [self decodeWithEncodedURLString:&paramValue];
//
//                if (paramValue && paramKey) {
//                    [queryParams setValue:paramValue forKey:paramKey];
//                }
//            }
//        }];
//    }
//
//    return [queryParams copy];
//}

//+ (NSString *)hostForURL:(NSURL *)url
//{
//    NSString *urlString = [url absoluteString];
//    if (!url || urlString.length == 0) {
//        NSAssert(NO, @"url为空，请确保url创建成功!");
//        return nil;
//    }
//
//    NSString *host = nil;
//    NSRange schemeSegRange = [urlString rangeOfString:@"://"];
//    NSString *outScheme = nil;
//    if (schemeSegRange.location != NSNotFound) {
//        outScheme = [urlString substringFromIndex:NSMaxRange(schemeSegRange)];
//    }
//    else {
//        outScheme = urlString;
//    }
//
//    NSArray *substrings = [outScheme componentsSeparatedByString:@"?"];
//    NSString *path = [substrings objectAtIndex:0];
//    NSArray *hostSeg = [path componentsSeparatedByString:@"/"];
//
//    host = [hostSeg objectAtIndex:0];
//    return host;
//}

static NSCharacterSet *set = nil;

+ (NSString*)urlCustomEncodeWithUrl:(NSString*)url
{
    if (!set) {
        NSMutableCharacterSet *mutableSet = NSMutableCharacterSet.alphanumericCharacterSet;
        [mutableSet formIntersectionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"#:/;?+-.@&=%$_!*'(),{}|^~[]`<>\\\""]];
        set = mutableSet.invertedSet;
    }
    
    return [url stringByAddingPercentEncodingWithAllowedCharacters:set];
}

+ (NSURL *)URLWithString:(NSString *)str relativeToURL:(NSURL *)url
{
    if (!str || ![str isKindOfClass:[NSString class]] ||!str.length) {
        return nil;
    }
    NSString *fixStr = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURL *u = nil;
    if (url) {
        u = [NSURL URLWithString:fixStr relativeToURL:url];
    }
    else {
        u = [NSURL URLWithString:fixStr];
    }
    if (!u) {
        //直接创建url失败，则进行query encode尝试
        NSString *sourceString = fixStr;
        NSRange fragmentRange = [fixStr rangeOfString:@"#"];
        NSString *fragment = nil;
        if (fragmentRange.location != NSNotFound) {
            sourceString = [fixStr substringToIndex:fragmentRange.location];
            fragment = [fixStr substringFromIndex:fragmentRange.location];
        }
        NSArray *substrings = [sourceString componentsSeparatedByString:@"?"];
        if ([substrings count] > 1) {
            NSString *beforeQuery = [substrings objectAtIndex:0];
            NSString *queryString = [substrings objectAtIndex:1];
            NSArray *paramsList = [queryString componentsSeparatedByString:@"&"];
            NSMutableDictionary *encodedQueryParams = [NSMutableDictionary dictionary];
            [paramsList enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL *stop) {
                NSArray *keyAndValue = [param componentsSeparatedByString:@"="];
                if ([keyAndValue count] > 1) {
                    NSString *key = [keyAndValue objectAtIndex:0];
                    NSString *value = [keyAndValue objectAtIndex:1];
                    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    if (![value rangeOfString:@"%"].length) {
                        value = (__bridge_transfer NSString *)(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)value, CFSTR(""), kCFStringEncodingUTF8));
                    }
                    
                    CFStringRef cfValue = (__bridge CFStringRef)value;
                    CFStringRef encodedValue = CFURLCreateStringByAddingPercentEscapes(
                                                                                       kCFAllocatorDefault,
                                                                                       cfValue,
                                                                                       NULL,
                                                                                       CFSTR(":/?#@!$&'() {}*+="),
                                                                                       kCFStringEncodingUTF8);
#pragma clang diagnostic pop
                    value = (__bridge_transfer NSString *)encodedValue;
                    [encodedQueryParams setValue:value forKey:key];
                }
            }];
            
            NSMutableString *temp = [NSMutableString stringWithCapacity:20];
            [encodedQueryParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [temp appendFormat:@"%@=%@&", key, obj];
            }];
            if (temp.length > 0) {
                // 删除最后的&
                [temp deleteCharactersInRange:NSMakeRange(temp.length - 1, 1)];
            }
            NSString *encodedQuery = [temp copy];
            
            
            NSString *encodedURLString = [[[beforeQuery stringByAppendingString:@"?"] stringByAppendingString:encodedQuery] stringByAppendingString:fragment?:@""];
            
            if (url) {
                u = [NSURL URLWithString:encodedURLString relativeToURL:url];
            }
            else {
                u = [NSURL URLWithString:encodedURLString];
            }
        }
        /*
         *   http://p1.meituan.net/adunion/a1c87dd93958f3e7adbeb0ecf1c5c166118613.jpg@228w|0_2_0_150az
         *   上面的链接没有命中特殊字符串转义逻辑，在上溯逻辑之后再尝试转义之后转url。。。       --yingjie
         */
        if (!u) {
            u = [NSURL URLWithString:[fixStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        
        NSAssert(u, @"url构造出现问题，请确保格式合法，或联系专业人士");
    }
    return u;
}

#pragma mark - Config Params
//+ (void)decodeWithEncodedURLString:(NSString **)urlString
//{
//    if ([*urlString rangeOfString:@"%"].length == 0) {
//        return;
//    }
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//    *urlString = (__bridge_transfer NSString *)(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)*urlString, CFSTR(""), kCFStringEncodingUTF8));
//#pragma clang diagnostic pop
//}

+ (NSString *)contentTypeForImageData:(NSData *)data
{
    NSString *mimeType = [BDPImageHelper mimeTypeForImageData:data];
    NSArray<NSString *> *components = [mimeType componentsSeparatedByString:@"/"];
    if (components.count != 2) {
        return nil;
    }
    
    return components.lastObject;
}

+ (CGFloat)adjustHeight:(CGFloat)height maxHeight:(CGFloat)maxHeight minHeight:(CGFloat)minHeight
{
    if (minHeight && height < minHeight) {
        height = minHeight;
    }
    if (maxHeight && height > maxHeight) {
        height = maxHeight;
    }
    return height;
}

+ (CGSize)adjustSize:(CGSize)size orientation:(BOOL)orientation
{
    if ((orientation && size.width < size.height) || (!orientation && size.width > size.height)) {
        return CGSizeMake(size.height, size.width);
    }
    return size;
}

+ (NSString *)randomString
{
    NSString *alphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: 15];
    for (int i = 0; i < 16; i++) {
        [randomString appendFormat: @"%C", [alphabet characterAtIndex:arc4random_uniform((int)[alphabet length])]];
    }
    return randomString;
}

+ (void)showAlertVC:(UIViewController *)alertVC inController:(UIViewController *)controller
{
    UIWindow *window = controller.view.window ?: OPWindowHelper.fincMainSceneWindow;
    if ([BDPDeviceHelper isPadDevice]) {
        UIPopoverPresentationController *popPresenter = [alertVC popoverPresentationController];
        popPresenter.sourceView = window;
        popPresenter.sourceRect = window.bounds;
    }
    [controller presentViewController:alertVC animated:YES completion:nil];
}

@end
