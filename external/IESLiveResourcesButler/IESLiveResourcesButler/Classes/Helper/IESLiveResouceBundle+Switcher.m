//
//  IESLiveResouceBundle+Switcher.m
//  Pods
//
//  Created by Zeus on 2017/1/6.
//
//

#import "IESLiveResouceBundle+Switcher.h"
#import "IESLiveResouceBundle+Loader.h"
#import "IESLiveResouceBundle+Hooker.h"

@implementation IESLiveResouceBundle (Switcher)

+ (void)switchToBundle:(NSString *)bundleName forCategory:(NSString *)category {
    
    if (!category || !bundleName) {
        return;
    }
    
    //记录下来原始的category=>bundle信息
    //因为bundle的pageurl不能切换，否则可能造成无法跳转
    static NSMutableDictionary<NSString *,IESLiveResouceBundle *> *originBundleMap = nil;
    static NSMutableDictionary<NSString *,IESLiveResouceBundle *> *selectedBundleMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        originBundleMap = [NSMutableDictionary dictionary];
        selectedBundleMap = [NSMutableDictionary dictionary];
    });
    
    if (!originBundleMap[category]) {
        originBundleMap[category] = [IESLiveResouceBundle assetBundleWithCategory:category];
    }
    
    [IESLiveResouceBundle useBundle:bundleName forCategory:category];
    IESLiveResouceBundle *bundle = [IESLiveResouceBundle assetBundleWithCategory:category];
    IESLiveResouceBundle *originBundle = originBundleMap[category];
    selectedBundleMap[category] = bundle;
    if (originBundle && ![bundle.bundleName isEqualToString:[originBundle bundleName]]) {
        [bundle removeAllHookers];
        [bundle addPreHook:^id(NSString *key, NSString *type, NSString *hcategory) {
            if ([category isEqualToString:hcategory] && [type isEqualToString:@"pageurl"]) {
                return [originBundle objectForKey:key type:type];
            }
            return nil;
        }];
    }
}

@end
