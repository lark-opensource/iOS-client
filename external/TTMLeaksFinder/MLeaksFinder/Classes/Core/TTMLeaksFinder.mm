//
//  MLeaksFinder.m
//  MLeaksFinder
//
//  Created by xushuangqing on 2019/8/12.
//

#import "TTMLeaksFinder.h"
#import <FBRetainCycleDetector/FBObjectGraphConfiguration.h>
#import <FBRetainCycleDetector/FBAssociationManager.h>
#import <FBRetainCycleDetector/FBStandardGraphEdgeFilters.h>
#import "TTMLOperationManager.h"
#import "TTMLBlockNodeInterpreter.h"

static TTMLeaksConfig * MLeaksCurrentConfig;
static NSMutableSet<Class> *MLeaksClassWhiteList;

NSArray<FBGraphEdgeFilterBlock> * MLeaksFileters;

//合并自定义filters和默认filters
static void updateFilters() {
    NSMutableArray<FBGraphEdgeFilterBlock> *retainFilterBlocks = [NSMutableArray new];
    
    NSDictionary<NSString *, NSArray<NSString *> *> *retainFilters = [TTMLeaksFinder memoryLeaksConfig].filters;
    
    //retainFilters的格式也是如此
    NSDictionary<NSString *, NSArray<NSString *> *> *defaultRetainFilters = @{
        @"UITouch" : @[@"_view",
                     @"_gestureRecognizers",
                     @"_window",
                     @"_warpedIntoView",
                     @"__windowServerHitTestWindow"],
        @"UITextTapRecognizer" : @[@"_touchesForTap"],
        @"AVUserInteractionObserverGestureRecognizer" : @[@"_trackedTouches"],
        @"UITapAndAHalfRecognizer" : @[@"_touch"],
        @"UIGestureRecognizer" : @[@"_activeEvents",
                                 @"_activeTouches",
                                 @"_touches",
                                 @"_touch",
                                 @"_movingTouches",
                                 @"_internalActiveTouches",
                                 @"_delayedTouches"],
        @"UITapRecognizer" : @[@"_touches", @"_activeTouches"],
        @"UIAlertController" : @[@"_accessibilityViewControllerForSizing"],
        @"UINavigationController" : @[@"__transitionController"],
        @"_UIViewControllerOneToOneTransitionContext" : @[@"_toViewController",
                                                        @"_fromViewController",
                                                        @"_presentingViewController",
                                                        @"_temporaryPresentationController"],
        @"UIApplication" : @[@"_statusBarTintColorLockingControllers"],
        @"_UINavigationParallaxTransition" : @[@"_transitionContext"],
        @"UIStatusBar" : @[@"_statusBarServer"],
        @"UIFieldEditor" : @[@"_proxiedView"],
        @"UISwipeActionsConfiguration" : @[@"_actions"],
        @"UIKeyboardHiddenViewController_Save" : @[@"_presentationController"],
        @"UIAlertAction" : @[@"_handler"],
        @"_UIOverFullscreenPresentationController" : @[@"_presentedViewController"],
        @"_UISheetInteraction" : @[@"_dragSource"],
        @"_UIActivityUserDefaultsViewController" : @[@"_diffableDataSource"],
        @"UISwitchModernVisualElement" : @[@"_switchControl"],
        @"UITransitionView" : @[@"_originalWindow"],
        @"UIPresentationController" : @[@"_presentingViewController"]
    };
    
    NSMutableDictionary *mergedRetainFilters = [retainFilters mutableCopy];
    if (!mergedRetainFilters) {
        mergedRetainFilters = [NSMutableDictionary new];
    }
    
    [defaultRetainFilters enumerateKeysAndObjectsWithOptions:0 usingBlock:^(NSString * _Nonnull key, NSArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
        NSArray<NSString *> *functionNames = [mergedRetainFilters valueForKey:key];
        if ([functionNames count]) { //如果已有这个className，则merge方法名
            NSArray<NSString *> *functionNamesAfterMerge = [functionNames arrayByAddingObjectsFromArray:obj];
            [mergedRetainFilters setValue:functionNamesAfterMerge forKey:key];
        }
        else { //如果没有这个className，直接使用默认方法名
            [mergedRetainFilters setValue:obj forKey:key];
        }
    }];
    
    [mergedRetainFilters enumerateKeysAndObjectsWithOptions:0 usingBlock:^(NSString * _Nonnull key, NSArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
        Class clazz = NSClassFromString(key);
        if (clazz) {
            FBGraphEdgeFilterBlock block = FBFilterBlockWithObjectToManyIvarsRelation(clazz, [NSSet setWithArray:obj]);
            if (block) {
                [retainFilterBlocks addObject:block];
            }
        }
    }];
    MLeaksFileters = retainFilterBlocks;
}


@implementation TTMLeaksFinder

#ifdef TTMLeaksFinder_POD_VERSION
NSString * const TTMLeaksFinderVersion = TTMLeaksFinder_POD_VERSION;
#else
NSString * const TTMLeaksFinderVersion = @"13_2.0.0";
#endif


+ (NSString *)version {
    if ([TTMLeaksFinderVersion hasPrefix:@"13_"]) {
        return [TTMLeaksFinderVersion substringFromIndex:3];
    }
    return @"2.0.0";
}

+ (void)startDetectMemoryLeakWithConfig:(TTMLeaksConfig *)config {
    if (!config) {
        NSAssert(NO, @"Error: startDetectMemoryLeakWithConfig config params can not be nil");
    }
    TTMLBlockNodeInterpreter *blockInterpreter = [TTMLBlockNodeInterpreter new];//符号化相关
    [TTMLLeakCycleNode registerInterpreter:@[blockInterpreter]];
    MLeaksCurrentConfig = config;
    [self updateMemoryLeakConfig];
}

+ (void)stopDetectMemoryLeak {
    MLeaksCurrentConfig = nil;
    [self tt_updateAssociationHook:NO];
    [TTMLLeakCycleNode removeAllInterpreters];
}

+ (void)updateMemoryLeakConfig {
    if (MLeaksCurrentConfig) {
        [self tt_updateAssociationHook:MLeaksCurrentConfig.enableAssociatedObjectHook];
        updateFilters();
        [self updateClassWhiteList];
    }
}

//所有 FBAssociationManager 开关需要走这个方法
+ (void)tt_updateAssociationHook:(BOOL)hook {
    static BOOL isHooked = NO;
    if (hook) {
        if (!isHooked) {
            [FBAssociationManager hook];
        }
        isHooked = YES;
    }
    else {
        if (isHooked) {
            [FBAssociationManager unhook];
        }
        isHooked = NO;
    }
}

+ (TTMLeaksConfig *)memoryLeaksConfig {
    return MLeaksCurrentConfig;
}

+ (void)updateClassWhiteList {
    NSMutableSet *whitelist = [NSMutableSet setWithObjects:
                 @"UIFieldEditor", // UIAlertControllerTextField
                 @"UINavigationBar",
                 @"_UIAlertControllerActionView",
                 @"_UIVisualEffectBackdropView",
                 nil];
    
    // System's bug since iOS 10 and not fixed yet up to this ci.
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    if ([systemVersion compare:@"10.0" options:NSNumericSearch] != NSOrderedAscending) {
        [whitelist addObject:@"UISwitch"];
    }
    if (MLeaksCurrentConfig.classWhitelist.count > 0) {
        [whitelist addObjectsFromArray:MLeaksCurrentConfig.classWhitelist];
    }
    
    NSMutableSet<Class> *clazzWhiteList = [[NSMutableSet alloc] init];
    [whitelist enumerateObjectsUsingBlock:^(NSString * _Nonnull clazzName, BOOL * _Nonnull stop) {
        Class whiteListClazz = NSClassFromString(clazzName);
        if (whiteListClazz) {
            [clazzWhiteList addObject:whiteListClazz];
        }
    }];
    NSLog(@"%@", MLeaksCurrentConfig.classWhitelist.description);
    NSLog(@"%@",clazzWhiteList.description);
    
    MLeaksClassWhiteList = clazzWhiteList;
}

+ (NSMutableSet<Class> *)classNamesWhitelist {
    return MLeaksClassWhiteList;
}

+ (void)manualCheckRootObject:(id)rootObject {
    if (!rootObject) {
        return;
    }
    [[TTMLOperationManager sharedManager] startBuildingRetainTreeForRoot:rootObject];
    [[TTMLOperationManager sharedManager] startDetectingSurviveObjectsForRootAfterDelay:rootObject];
//    [rootObject tt_startCheckMemoryLeaks];
}



@end
