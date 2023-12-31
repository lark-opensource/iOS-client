////
//  BDPTask+BDPJSRuntimeDelegate
//  Timor
//
//  Created by qsc on 2020/10/28.
//  Copyright © ByteDance. All rights reserved.
//


#import "BDPTask+BDPJSRuntimeDelegate.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import "BDPAppRouteManager.h"
#import "BDPBaseContainerController.h"
#import "BDPGadgetLog.h"

@interface BDPTask()
@property (nonatomic, assign) BOOL enablePublishLog;
@end

@implementation BDPTask(BDPJSRuntimeDelegate)


-(void)jsRuntimePublishMessage:(NSString *)event param:(NSDictionary *)param appPageIDs:(NSArray<NSNumber *> *)appPageIDs {
    NSArray<BDPAppPage *> *appPages = [self.pageManager appPagesWithIDs:appPageIDs];
    if(self.enablePublishLog) {
        BDPGadgetLogInfo(@"fireEvent to appPageIDs: %@", appPageIDs);
    }
    
    // 在AppPage注册前就调用JSC的方法, 比如onAppRoute或者RedictTo等, 可能导致丢消息
    if (![appPageIDs.firstObject isKindOfClass:[NSNull class]] && appPageIDs.count > 0 && appPages.count == 0) {
        // 此处简单处理延时0.5s执行
        BDPGadgetLogWarn(@"can't find apppage to handle publish msg!")
        WeakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn;
            NSArray<BDPAppPage *> *appPages = [self.pageManager appPagesWithIDs:appPageIDs];
            for (BDPAppPage *appPage in appPages) {
                [appPage bdp_fireEvent:event sourceID:appPage.appPageID data:param];
            }
        });
    } else {
        for (BDPAppPage *appPage in appPages) {
            [appPage bdp_fireEvent:event sourceID:appPage.appPageID data:param];
        }
    }
}

-(UIViewController *)jsRuntimeController {
    if(self.containerVC && [self.containerVC isKindOfClass:[BDPBaseContainerController class]]) {
        BDPBaseContainerController *vc = (BDPBaseContainerController *)self.containerVC;
        return vc.subNavi.topViewController;
    } else {
        NSString *traceID = [BDPTracingManager.sharedInstance getTracingByUniqueID:self.uniqueID].traceId;
        BDPGadgetLogError(@"JSRuntime delegate Can not provide current ViewController!, trace-ID: %@", traceID);
    }
    return nil;
}

-(void)jsRuntimeOnDocumentReady {
    BDPAppPage *appPage = [self.pageManager appPageWithPath:self.currentPage.path];
    [BDPAppRouteManager postDocumentReadyNotifWithUniqueId:self.uniqueID appPageId:appPage.appPageID];
    BDPGadgetLogInfo(@"JSRuntime ready: %@", @(appPage.appPageID));
}


#pragma mark - 真机调试相关

/**
 * 真机调试目前实现方式比较 tricky，继承了 JSRuntime , 需要对 VC 发送一些相关事件信息
 * 由于早期的实现中，VC 实现 JSRuntimeDelegate, JSRuntime 会把消息直接发给 VC
 *  > 但是导致的问题是 VC 与 JSRuntime 生命周期不匹配，导致消息会丢失。
 *  > 故把 JSRuntime.delegate 切换为 BDPTask，但 BDPTask 中的 ContainerVC 的 ContainerProtocol 未提供相关方法
 * 故此处对  ContainerProtocol 做了修改，添加了真机调试相关需求。
 */
- (void)onSocketDebugConnected {
    if(self.containerVC && [self.containerVC respondsToSelector:@selector(onSocketDebugConnected)]) {
        [self.containerVC onSocketDebugConnected];
    }
}

- (void)onSocketDebugConnectFailed {
    if(self.containerVC && [self.containerVC respondsToSelector:@selector(onSocketDebugConnectFailed)]) {
        [self.containerVC onSocketDebugConnectFailed];
    }
}


- (void)onSocketDebugDisconnected {
    if(self.containerVC && [self.containerVC respondsToSelector:@selector(onSocketDebugDisconnected)]) {
        [self.containerVC onSocketDebugDisconnected];
    }
}

- (void)onSocketDebugPauseInspector {
    if(self.containerVC && [self.containerVC respondsToSelector:@selector(onSocketDebugPauseInspector)]) {
        [self.containerVC onSocketDebugPauseInspector];
    }
}

- (void)onSocketDebugResumeInspector {
    if(self.containerVC && [self.containerVC respondsToSelector:@selector(onSocketDebugResumeInspector)]) {
        [self.containerVC onSocketDebugResumeInspector];
    }
}

@end
