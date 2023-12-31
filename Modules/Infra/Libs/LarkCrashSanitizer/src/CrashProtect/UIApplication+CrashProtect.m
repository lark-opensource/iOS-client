//
//  UIApplication+CrashProtect.m
//  LarkCrashSanitizer
//
//  Created by 李晨 on 2021/3/1.
//

#import <objc/runtime.h>
#import <LarkCrashSanitizer/LarkCrashSanitizer-Swift.h>
#import <UIKit/UIKit.h>
#import <LarkFoundation/LKEncryptionTool.h>
#import "LKHookUtil.h"
#import <LKLoadable/Loadable.h>

// app 启动时间
static NSTimeInterval application_protect_startTime = 0;
// app 最后一次退到后台的时间
static NSTimeInterval application_last_enter_background_time = -1;

@interface UIScene (crash)

@end

@implementation UIScene (crash)

- (BOOL)sceneHadDestruction {
    NSNumber* value = objc_getAssociatedObject(self, @selector(sceneHadDestruction));
    if (value == NULL) {
        return NO;
    }
    return [value boolValue];
}

- (void)setSceneHadDestruction:(BOOL)sceneHadDestruction {
    objc_setAssociatedObject(self, @selector(sceneHadDestruction), @(sceneHadDestruction), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface UIApplication (crash)

@end

@implementation UIApplication (crash)

- (void)hook_beginSnapshotSessionForScene:(id)scene withSnapshotBlock:(id)block {
    if (@available(iOS 13.0, *)) {
        NSString* logInfo = [[NSString alloc] initWithFormat:@"beginSnapshotSessionForScene %@ scene count %lu", scene, (unsigned long)[[[UIApplication sharedApplication] connectedScenes] count]];
        [WMFSwiftLogger infoWithMessage: logInfo];
    }
    CGFloat currentTime = [[NSDate date] timeIntervalSince1970];
    if (scene == NULL) {
        return;
    }

    // 启动 15s 内不响应 beginSnapshotSessionForScene 避免启动卡死
    if ((currentTime - application_protect_startTime) < 15) {
        return;
    }
    // 退到后台 15s 后不再响应截屏方法，避免后台任务导致卡死
    if ((currentTime - application_last_enter_background_time) > 15 ||
        application_last_enter_background_time == -1) {
        return;
    }
    // 没有开启多窗口功能的 identifier UDID 显示为 default
    NSString *identifier = [scene valueForKey: @"identifier"];
    UIScene* result = [self findSceneByFBSSessionID: identifier];
    // 没有开启多窗口功能 或者 当前 scene 没有被销毁则运行系统 snapshot 函数
    if ([identifier containsString: @"default"] || (result != NULL && ![result sceneHadDestruction])) {
        [self hook_beginSnapshotSessionForScene:scene withSnapshotBlock:block];
    }
}

- (void)cp_requestSceneSessionDestruction:(UISceneSession *)sceneSession options:(nullable UISceneDestructionRequestOptions *)options errorHandler:(nullable void (^)(NSError * error))errorHandle {
    UIScene* result = [self findSceneBySession: sceneSession];
    if (result != NULL) {
        [result setSceneHadDestruction: YES];
    }

    [self cp_requestSceneSessionDestruction:sceneSession options:options errorHandler:errorHandle];
}

- (UIScene *)findSceneBySession: (UISceneSession *)sceneSession {
    UIScene* result;
    UIScene* scene;
    NSEnumerator *enumerator = [self.connectedScenes objectEnumerator];
    while (scene = [enumerator nextObject]) {
        if ([scene session] == sceneSession) {
            result = scene;
            break;
        }
    }
    return result;
}

- (UIScene *)findSceneByFBSSessionID: (NSString *)identifier {
    UIScene* result;
    UIScene* scene;
    NSEnumerator *enumerator = [self.connectedScenes objectEnumerator];
    while (scene = [enumerator nextObject]) {
        if ([identifier containsString: scene.session.persistentIdentifier]) {
            result = scene;
            break;
        }
    }
    return result;
}

@end

LoadableMainFuncBegin(crashProtect)
if (@available(iOS 13.0, *)) {
    // hook snapshot 方法 避免卡死
    SwizzleMethod([UIApplication class], @selector(_beginSnapshotSessionForScene:withSnapshotBlock:), [UIApplication class], @selector(hook_beginSnapshotSessionForScene:withSnapshotBlock:));
    // hook scene 销毁方法 标记 scene 已经销毁
    SwizzleMethod([UIApplication class], @selector(requestSceneSessionDestruction:options:errorHandler:), [UIApplication class], @selector(cp_requestSceneSessionDestruction:options:errorHandler:));
    // 记录启动时间
    application_protect_startTime = [[NSDate date] timeIntervalSince1970];
}

// 监听退到后台通知
[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note) {
    application_last_enter_background_time = [[NSDate date] timeIntervalSince1970];
}];
LoadableMainFuncEnd(crashProtect)

