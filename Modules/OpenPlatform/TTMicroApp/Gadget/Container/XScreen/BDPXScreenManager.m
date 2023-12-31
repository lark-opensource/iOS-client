//
//  BDPXScreenManager.h
//  TTMicroApp
//
//  Created by qianhongqiang on 2022/8/30.
//

#import "BDPXScreenManager.h"
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPCommonManager.h>
#import "BDPTimorClient+Business.h"
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/EEFeatureGating.h>

@interface BDPXScreenManager()

@end

@implementation BDPXScreenManager

+ (BOOL)isXScreenMode:(BDPUniqueID *)uniqueID {
    
    if (![self isXScreenFGConfigEnable]) {
        return NO;
    }
    
    // iPad首期不支持半屏模式
    if ([BDPDeviceHelper isPadDevice]) {
        return NO;
    }
    
    BDPPlugin(XScreenPlugin, BDPXScreenPluginDelegate);
    if ([XScreenPlugin isXscreenModeWhileLaunchingForUniqueID:uniqueID]) {
        return YES;
    }
    
    return NO;
}

+ (CGFloat)XScreenPresentationRate:(BDPUniqueID *)uniqueID {
    BDPPlugin(XScreenPlugin, BDPXScreenPluginDelegate);
    NSString *style = [XScreenPlugin XScreenPresentationStyleWhileLaunchingForUniqueID:uniqueID];
    return [self castPresentationStyleToRate:style];
}

+ (nullable NSString *)XScreenPresentationStyle:(BDPUniqueID *)uniqueID {
    BDPPlugin(XScreenPlugin, BDPXScreenPluginDelegate);
    return [XScreenPlugin XScreenPresentationStyleWhileLaunchingForUniqueID:uniqueID];
}

+ (CGFloat)XScreenAppropriatePresentationHeight:(BDPUniqueID *)uniqueID {
    CGFloat castRate = [self XScreenPresentationRate:uniqueID];
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    return MAX(floor(screenHeight * castRate), 300.f);
}

+ (CGFloat)XScreenAppropriateMaskHeight:(BDPUniqueID *)uniqueID {
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    return screenHeight - [self XScreenAppropriatePresentationHeight:uniqueID];
}

+ (CGFloat)castPresentationStyleToRate:(NSString *)style {
    if (style && [style length] > 0) {
        NSDictionary *rateMap = @{
            @"high":@(0.86),
            @"medium":@(0.65),
            @"low":@(0.45)
        };
        NSNumber *rate = rateMap[style];
        
        return rate ? [rate floatValue] : 0.86f;
    }
    
    // 默认占比86%
    return 0.86f;
}

+ (BOOL)isXScreenFGConfigEnable {
    static BOOL ret = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = [EEFeatureGating boolValueForKey: EEFeatureGatingKeyXScreenGadgetEnable];
    });
    return ret;
}

@end
