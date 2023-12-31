//
//  UIDevice+AWEAdditions.m
//  Aweme
//
//  Created by hanxu on 2017/4/6.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "UIDevice+AWEAdditions.h"
#include <sys/sysctl.h>
#import "AWEMacros.h"
#import <sys/utsname.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>


typedef enum : NSUInteger {
    AWEDeviceModelTypeUnknown,
    AWEDeviceModelTypeiPhone,
    AWEDeviceModelTypeiPad,
    AWEDeviceModelTypeiPodTouch,
} AWEDeviceModelType;

@interface AWEDeviceModelInfo: NSObject

@property (nonatomic, assign) AWEDeviceModelType type;

@property (nonatomic, assign) NSInteger generation;
@property (nonatomic, assign) NSInteger serial;

@property (nonatomic, assign) BOOL isAChip;
@property (nonatomic, assign) NSInteger chipGeneration;
@property (nonatomic, assign) BOOL graphicsPowerChip;

@end

@implementation AWEDeviceModelInfo

@end


@implementation UIDevice (AWEAdditions)
+ (NSString *)awe_machineModel
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *machineModel = [NSString stringWithUTF8String:machine];
    free(machine);
    return machineModel;
}

+ (AWEDeviceCarrierCodeType)awe_deviceCarrierCode
{
    AWEDeviceCarrierCodeType carrierCode;
    NSString *phoneMNC = [UIDevice awe_btd_carrierMNC];
    NSString *phoneMCC = [UIDevice awe_btd_carrierMCC];
    NSArray *mobileMNC = @[@"00", @"02", @"07", @"08"];
    NSArray *unicomMNC = @[@"01", @"06", @"09"];
    NSArray *telecomMNC = @[@"03", @"05", @"11"];
    if ([phoneMCC isKindOfClass:[NSString class]] && [phoneMCC isEqualToString:@"460"]) {
        if ([telecomMNC containsObject:phoneMNC]) {
            carrierCode = AWEDeviceCarrierCoceTypeTelecom;
        } else if ([unicomMNC containsObject:phoneMNC]) {
            carrierCode = AWEDeviceCarrierCodeTypeUnicom;
        } else if ([mobileMNC containsObject:phoneMNC]) {
            carrierCode = AWEDeviceCarrierCodeTypeMobile;
        } else {
            carrierCode = AWEDeviceCarrierCodeTypeUnknown;
        }
    } else {
        carrierCode = AWEDeviceCarrierCodeTypeUnknown;
    }
    return carrierCode;
}

+ (NSString*)awe_btd_carrierMNC
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];
    NSString *mnc = [carrier mobileNetworkCode];
    return mnc;
}

+ (NSString*)awe_btd_carrierMCC
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];
    NSString *mcc = [carrier mobileCountryCode];
    return mcc;
}

+ (NSString *)awe_btd_machineModel
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *machineModel = [NSString stringWithUTF8String:machine];
    free(machine);
    return machineModel;
}

+ (AWEDeviceModelInfo *)awe_deviceModel
{
    static AWEDeviceModelInfo *modelInfo;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        modelInfo = [[AWEDeviceModelInfo alloc] init];
        NSString *platformStr = [UIDevice awe_btd_machineModel];
        NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"^([a-zA-Z]+)(\\d+),(\\d+)" options:0 error:nil];
        NSTextCheckingResult *result = [reg firstMatchInString:platformStr options:0 range:NSMakeRange(0, platformStr.length)];
        if (result) {
            NSString *device = [platformStr substringWithRange:[result rangeAtIndex:1]];
            NSInteger generation = [platformStr substringWithRange:[result rangeAtIndex:2]].integerValue;
            NSInteger tag = [platformStr substringWithRange:[result rangeAtIndex:3]].integerValue;
            if ([device isEqualToString:@"iPhone"]) {
                modelInfo.type = AWEDeviceModelTypeiPhone;
                // iPhone 4 (iPhone3,1) 以前用的不是 A 系列芯片
                if (generation >= 3) {
                    modelInfo.isAChip = YES;
                    modelInfo.chipGeneration = generation + 1;
                    modelInfo.graphicsPowerChip = NO;
                } else {
                    modelInfo.isAChip = NO;
                }
            } else if ([device isEqualToString:@"iPad"]) {
                modelInfo.type = AWEDeviceModelTypeiPad;
                modelInfo.isAChip = YES;
                if (generation == 3) {
                    modelInfo.graphicsPowerChip = YES;
                    if (tag <= 3) {
                        // iPad 3 (iPad3,1-3) A5X
                        modelInfo.chipGeneration = 5;
                    } else {
                        // iPad 4 (iPad3,4-6) A6X
                        modelInfo.chipGeneration = 6;
                    }
                } else {
                    modelInfo.chipGeneration = generation + 3;
                    modelInfo.graphicsPowerChip = NO;
                    
                    if (generation <= 2) {
                        modelInfo.graphicsPowerChip = NO;
                    } else if (generation == 4) {
                        modelInfo.graphicsPowerChip = NO;
                    } else if (generation == 5) {
                        if (tag <= 2) {
                            // iPad mini 4 - A8
                            modelInfo.graphicsPowerChip = NO;
                        } else {
                            // iPad Air 2 - A8X
                            modelInfo.graphicsPowerChip = YES;
                        }
                    } else if (generation == 6) {
                        if (tag >= 11) {
                            // iPad (2017) - A9
                            modelInfo.graphicsPowerChip = NO;
                        } else {
                            // iPad Pro 12.9 inch (2016), iPad Pro 9.7 inch - A9X
                            modelInfo.graphicsPowerChip = YES;
                        }
                    } else {
                        // iPad Pro 12.9 inch (2017), iPad Pro 10.5 inch - A10X
                        // 未来的 iPad 默认猜测是带 X 的
                        modelInfo.graphicsPowerChip = YES;
                    }
                }
            } else if ([device isEqualToString:@"iPod"]) {
                modelInfo.type = AWEDeviceModelTypeiPodTouch;
                modelInfo.graphicsPowerChip = NO;
                if (generation < 4) {
                    modelInfo.isAChip = NO;
                } else if (generation < 6) {
                    modelInfo.isAChip = YES;
                    modelInfo.chipGeneration = generation;
                } else {
                    // iPod Touch 6 (iPod7,1) - A8
                    modelInfo.isAChip = YES;
                    modelInfo.chipGeneration = generation + 1;
                }
            }
            modelInfo.generation = generation;
            modelInfo.serial = tag;
        }
    });
    return modelInfo;
}

+ (BOOL)awe_isBetterThanIPhone7
{
    AWEDeviceModelInfo *info = [self awe_deviceModel];
    return info.chipGeneration >= 10;
}

+ (BOOL)awe_isIPhone7Plus
{
    AWEDeviceModelInfo *info = [self awe_deviceModel];
    return info.type == AWEDeviceModelTypeiPhone && info.generation == 9 && (info.serial == 2 || info.serial == 4);
}

+ (BOOL)awe_isIPhone {
    AWEDeviceModelInfo *info = [self awe_deviceModel];
    return info.type == AWEDeviceModelTypeiPhone;
}

+ (BOOL)awe_isPoorThanIPhone6S
{
    AWEDeviceModelInfo *info = [self awe_deviceModel];
    return info.chipGeneration < 9;
}

// iPhone6(iPhone7,2/A8)
+ (BOOL)awe_isPoorThanIPhone6
{
    AWEDeviceModelInfo *info = [self awe_deviceModel];
    return info.chipGeneration < 8;
}

+ (BOOL)awe_isPoorThanIPhone5s
{
    AWEDeviceModelInfo *info = [self awe_deviceModel];
    return info.chipGeneration < 7;
}

+ (BOOL)awe_isPoorThanIPhone5
{
    AWEDeviceModelInfo *info = [self awe_deviceModel];
    return info.chipGeneration < 6;
}

+ (AWEScreenWidthCategory)awe_screenWidthCategory
{
    CGFloat width = MIN([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    if (!FLOAT_GREATER_THAN(width, 320.f)) {
        return AWEScreenWidthCategoryiPhone5;
    } else if (!FLOAT_GREATER_THAN(width, 375.f)) {
        return AWEScreenWidthCategoryiPhone6;
    } else if (!FLOAT_GREATER_THAN(width, 414.f)) {
        return AWEScreenWidthCategoryiPhone6Plus;
    } else if (!FLOAT_GREATER_THAN(width, 768.f)) {
        return AWEScreenWidthCategoryiPad9_7;
    } else if (!FLOAT_GREATER_THAN(width, 834.f)) {
        return AWEScreenWidthCategoryiPad10_5;
    } else {
        return AWEScreenWidthCategoryiPad12_9;
    }
}

+ (AWEScreenHeightCategory)awe_screenHeightCategory
{
    CGFloat height = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    if (!FLOAT_GREATER_THAN(height, 480.f)) {
        return AWEScreenHeightCategoryiPhone4s;
    } else if (!FLOAT_GREATER_THAN(height, 568.f)) {
        return AWEScreenHeightCategoryiPhone5;
    } else if (!FLOAT_GREATER_THAN(height, 667.f)) {
        return AWEScreenHeightCategoryiPhone6;
    } else if (!FLOAT_GREATER_THAN(height, 736.f)) {
        return AWEScreenHeightCategoryiPhone6Plus;
    } else if (!FLOAT_GREATER_THAN(height, 812.f)) {
        return AWEScreenHeightCategoryiPhoneX;
    } else if (!FLOAT_GREATER_THAN(height, 896.f)) {
        return AWEScreenHeightCategoryiPhoneXSMax;
    } else if (!FLOAT_GREATER_THAN(height, 1024.f)) {
        return AWEScreenHeightCategoryiPad9_7;
    } else if (!FLOAT_GREATER_THAN(height, 1122.f)) {
        return AWEScreenHeightCategoryiPad10_5;
    } else {
        return AWEScreenHeightCategoryiPad12_9;
    }
}

+ (AWEScreenRatoCategory)awe_screenRatoCategory
{
    CGFloat width = MIN([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    CGFloat height = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    CGFloat rato = width / height;
    CGFloat distant4_3 = fabs((3.0f / 4.0f) - rato);
    CGFloat distant16_9 = fabs((9.0f / 16.0f) - rato);
    CGFloat distantX = fabs((375.0f / 812.0f) - rato);
    if (distant4_3 < distant16_9 && distant4_3 < distantX) {
        return AWEScreenRatoCategoryiPhone4_3;
    } else if (distant16_9 < distantX) {
        return AWEScreenRatoCategoryiPhone16_9;
    } else {
        return AWEScreenRatoCategoryiPhoneX;
    }
}

static NSInteger isIPhoneX = -1;
+ (BOOL)awe_isIPhoneX
{
    if (isIPhoneX < 0) {
        if (@available(iOS 11.0, *)) {
            // get UIScreen _peripheryInsets vaule, for iOS 12.*
            SEL peripheryInsetsSelector =  NSSelectorFromString([@[@"_",@"periph",@"eryI",@"nsets"] componentsJoinedByString:@""]);
            UIEdgeInsets peripheryInsets = UIEdgeInsetsZero;
            UIScreen *mainScreen = [UIScreen mainScreen];
            if ([mainScreen respondsToSelector:peripheryInsetsSelector]) {
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[mainScreen methodSignatureForSelector:peripheryInsetsSelector]];
                [invocation setTarget:mainScreen];
                [invocation setSelector:peripheryInsetsSelector];
                [invocation invoke];
                [invocation getReturnValue:&peripheryInsets];
            }
            
            if (peripheryInsets.bottom <= 0) {
                UIWindow *mainWindow = [[[UIApplication sharedApplication] windows] firstObject];
                BOOL shouldRemoveWindow = NO;
                if (!mainWindow) {
                    // 如果当前还没有创建window, 那就先创建一个临时的window，用于判断 safeArea, 之后会删除
                    mainWindow = [[UIWindow alloc] initWithFrame:mainScreen.bounds];
                    mainWindow.backgroundColor = [UIColor clearColor];
                    peripheryInsets = mainWindow.safeAreaInsets;
                    if (peripheryInsets.bottom <= 0) {
                        UIViewController *viewController = [UIViewController new];
                        mainWindow.rootViewController = viewController;
                        if (CGRectGetMinY(viewController.view.frame) > 20) {
                            peripheryInsets.bottom = 1;
                        }
                    }
                    shouldRemoveWindow = YES;
                } else {
                    peripheryInsets = mainWindow.safeAreaInsets;
                }
                if (shouldRemoveWindow) {
                    // 如果是临时的window，就删除掉。
                    [mainWindow removeFromSuperview];
                    mainWindow = nil;
                }
            }
            isIPhoneX = peripheryInsets.bottom > 0 ? 1 : 0;
        } else {
            isIPhoneX = 0;
        }
    }
    return isIPhoneX > 0;
}

+ (BOOL)awe_isIPhoneXsMax
{
    static BOOL isIPhoneXsMax = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isIPhoneXsMax = [self awe_screenHeightCategory] == AWEScreenHeightCategoryiPhoneXSMax;
    });
    return isIPhoneXsMax;
}

@end
