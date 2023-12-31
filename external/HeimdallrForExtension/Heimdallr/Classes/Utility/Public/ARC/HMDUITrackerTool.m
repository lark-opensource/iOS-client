//
//  HMDUITrackerTool.m
//  Pods
//
//  Created by bytedance on 2022/1/21.
//

#include <pthread.h>
#import <UIKit/UIKit.h>
#import "HMDUITrackerTool.h"
#import "HMDDynamicCall.h"
#import "UIApplication+HMDUtility.h"
#import "HMDMacro.h"

@implementation HMDUITrackerTool

#pragma mark - iOS 13.0+ window background status 判断 UIScene support

+ (BOOL)sceneBasedSupport {
    static BOOL globalDecided = NO;       // 是否已经查询 sceneBased 支持
    static BOOL globalEnableSupport;      // 查询到的结果
    
    // 当前全局是否已经判断完成
    BOOL currentDecided = __atomic_load_n(&globalDecided, __ATOMIC_ACQUIRE);
    
    // 如果全局已经判断完成，返回全局判断结果
    if(currentDecided) return __atomic_load_n(&globalEnableSupport, __ATOMIC_ACQUIRE);
    
    id maybeDictionary = nil;
    
    // 只有 iOS 13.0 + 查询 Info.plist
    if (@available(iOS 13.0, *))
        maybeDictionary = [NSBundle.mainBundle objectForInfoDictionaryKey:@"UIApplicationSceneManifest"];
    
    // 当前查询结果: 是否支持 SceneBased
    BOOL currentSceneBasedSupport = maybeDictionary != nil;
    
    // 写入全局判断结果
    if(currentSceneBasedSupport)
         __atomic_store_n(&globalEnableSupport, YES, __ATOMIC_RELEASE);
    else __atomic_store_n(&globalEnableSupport, NO,  __ATOMIC_RELEASE);
    
    // 写入全局是否判断
    __atomic_store_n(&globalDecided, YES, __ATOMIC_RELEASE);
    
    // 返回判断数据
    return currentSceneBasedSupport;
}

/*!@method keyWindow
 * @note [srw531] 断点注释
 * 如果断点暂停在这里，不是意味着崩溃，或者代码出现问题；是因为在我学习 iOS Multi window task UIScene 的时刻
 * UIKit 只会创建 UIWindowScene 对象, 如果这里断点，意味着需要更新代码兼容新的 UIScene subClass 加油～
 */
+ (UIWindow *)keyWindow {
    DEBUG_ASSERT(pthread_main_np());
    
    // 是否查询了 Application.sharedApplication.keyWindow 结果
    BOOL isApplicationKeyWindowSearched = NO;
    
    // 从 Application.sharedApplication.keyWindow 查询的结果
    UIWindow *applicationKeyWindow;
    
    // 在 iOS 13.0+ 出现了 sceneBasedApplication
    // 如果 APP 并没有 sceneBased
    if(!HMDUITrackerTool.sceneBasedSupport) {
        applicationKeyWindow = UIApplication.hmdSharedApplication.keyWindow;
        isApplicationKeyWindowSearched = YES;
        if(applicationKeyWindow != nil) return applicationKeyWindow;
    }
    
    // 如果在 iOS 13.0+
    if (@available(iOS 13.0, *)) {
        typedef enum: NSUInteger {
            HMDKeyWindowMatchLevelNone = 0,
            HMDKeyWindowMatchLevelBackground,
            HMDKeyWindowMatchLevelForegroundInActive,
            HMDKeyWindowMatchLevelForegroundActive,
        } HMDKeyWindowMatchLevel;
        
        HMDKeyWindowMatchLevel matchLevel = HMDKeyWindowMatchLevelNone;
        UIWindow *bestKeyWindow = nil;
        
        NSSet<UIScene *> *connectedScenes = UIApplication.hmdSharedApplication.connectedScenes;
        for(UIScene *eachScene in connectedScenes) {
            if([eachScene isKindOfClass:UIWindowScene.class]) {
                UIWindowScene *eachWindowScene = (__kindof UIWindowScene *)eachScene;
                if(eachWindowScene.activationState == UISceneActivationStateForegroundActive) {
                    
                    // 当前 window 属于 Fore Active
                    bestKeyWindow = [HMDUITrackerTool findKeyInWindows:eachWindowScene.windows];
                    // 如果在 foregroundActive 的 Window 里找到了 Key
                    if(bestKeyWindow != nil) {
                        // matchLevel = HMDKeyWindowMatchLevelForegroundActive;
                        // TODO: 注意这里实际上 WindowLevel 变化为了 HMDKeyWindowMatchLevelForegroundActive
                        break; // 不可能还有更好的选择，所以直接 break
                    }
                } else if(eachWindowScene.activationState == UISceneActivationStateForegroundInactive) {
                    
                    // 当前 window 属于 Fore Inactive
                    if(matchLevel < HMDKeyWindowMatchLevelForegroundInActive) {
                        UIWindow *maybe = [HMDUITrackerTool findKeyInWindows:eachWindowScene.windows];
                        if(maybe != nil) {
                            matchLevel = HMDKeyWindowMatchLevelForegroundInActive;
                            bestKeyWindow = maybe;
                        }
                    }
                } else if(eachWindowScene.activationState == UISceneActivationStateBackground) {
                    
                    // 当前 window 属于 Background
                    if(matchLevel < HMDKeyWindowMatchLevelBackground) {
                        UIWindow *maybe = [HMDUITrackerTool findKeyInWindows:eachWindowScene.windows];
                        if(maybe != nil) {
                            matchLevel = HMDKeyWindowMatchLevelBackground;
                            bestKeyWindow = maybe;
                        }
                    }
                }
                // Unattached 意味着只是在控制栏有界面，但是尚未初始化，也就是需要等待 NSUserActivity
                // else if(eachWindowScene.activationState == UISceneActivationStateUnattached) {}
                
            } DEBUG_ELSE // 断点注释 => srw531
            
        } // break exit for loop <=
        if(bestKeyWindow != nil) return bestKeyWindow;
    }
    
    // 如果还没有查询过 keyWindow 的话，兜底查找
    if(!isApplicationKeyWindowSearched)
        return UIApplication.hmdSharedApplication.keyWindow;
    
    // 怎么样都没找到 window 的话
    return nil;
}

+ (UIWindow * _Nullable)findKeyInWindows:(NSArray<UIWindow *> * _Nullable)windows {
    DEBUG_ASSERT(pthread_main_np());
    for(UIWindow *eachWindow in windows)
        if(eachWindow.isKeyWindow) return eachWindow;
    return nil;
}

+ (BOOL)isSceneBackground {
    DEBUG_ASSERT(pthread_main_np());
    
    // 在 iOS 13.0+ 出现了 sceneBasedApplication
    // 如果 APP 并没有 sceneBased
    if(!HMDUITrackerTool.sceneBasedSupport)
        return UIApplication.hmdSharedApplication.applicationState == UIApplicationStateBackground;
    
    // 如果在 iOS 13.0+
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *connectedScenes = UIApplication.hmdSharedApplication.connectedScenes;
        for(UIScene *eachScene in connectedScenes) {
            if([eachScene isKindOfClass:UIWindowScene.class]) {
                UIWindowScene *eachWindowScene = (__kindof UIWindowScene *)eachScene;
                UISceneActivationState activationState = eachWindowScene.activationState;
                if(activationState == UISceneActivationStateForegroundActive ||
                   activationState == UISceneActivationStateForegroundInactive)
                    return NO;
            } DEBUG_ELSE  // 断点注释 => srw531
        }
        return YES;
    }

    // 兜底返回 applicationState
    return UIApplication.hmdSharedApplication.applicationState == UIApplicationStateBackground;
}

@end

id<HMDUITrackerManagerSceneProtocol> hmd_get_uitracker_manager(void) {
    static id<HMDUITrackerManagerSceneProtocol> sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __kindof NSObject *maybeManager = DC_CL(HMDUITrackerManager, sharedManager);
        if([maybeManager conformsToProtocol:@protocol(HMDUITrackerManagerSceneProtocol)]) {
            sharedManager = maybeManager;
        }
    });
    return sharedManager;
}
