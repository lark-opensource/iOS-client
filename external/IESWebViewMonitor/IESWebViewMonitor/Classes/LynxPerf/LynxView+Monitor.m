//
//  LynxView+Monitor.m
//  
//
//  Created by admin on 2020/6/22.
//

#import "LynxView+Monitor.h"
#import "IESLynxMonitor.h"
#import <objc/runtime.h>
#import "IESLiveDefaultSettingModel.h"
#import "BDWMDeallocHelper.h"
#import "IESLynxPerformanceDictionary.h"
#import "IESLiveMonitorUtils.h"

@implementation LynxView (Monitor)

- (IESLynxPerformanceDictionary *)performanceDic {
    IESLynxPerformanceDictionary *dic = objc_getAssociatedObject(self, _cmd);
    
    if (!dic) {
        dic = [[IESLynxPerformanceDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return dic;
}

- (IESLynxMonitorConfig *)config {
    return self.performanceDic.config;
}

- (void)setConfig:(IESLynxMonitorConfig * _Nonnull)config {
    self.performanceDic.config = config;
}

- (void)setBdlm_bizTag:(NSString *)bdlm_bizTag {
    self.performanceDic.bizTag = bdlm_bizTag;
}

- (NSString *)bdlm_bizTag {
    return self.performanceDic.bizTag;
}

- (NSString *)bdlm_containerID {
    NSString *bdlm_containerID = objc_getAssociatedObject(self, _cmd);
    if (!bdlm_containerID) {
        bdlm_containerID = [NSUUID UUID].UUIDString;
        objc_setAssociatedObject(self, _cmd, bdlm_containerID, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return bdlm_containerID;
}

- (instancetype)bdlm_initWithBuilderBlock:(void (^)(NS_NOESCAPE LynxViewBuilder*))block {
    __weak __typeof(self)weakSelf = self;
    LynxView *obj = nil;
    Class monitorClass = NSClassFromString(@"BDLynxCustomErrorMonitor");
    Class moduleClass = NSClassFromString(@"BDLynxMonitorModule");
    SEL sel = NSSelectorFromString(@"customErrorEnable");
    IMP imp = nil;
    if(monitorClass) {
        imp = [monitorClass methodForSelector:sel];
    }
    BOOL customErrorEnable = NO;
    if(monitorClass && imp) {
        customErrorEnable = ((BOOL(*)(id, SEL))imp)(monitorClass, sel);
    }
    if(monitorClass && moduleClass && customErrorEnable) {
        obj = [self bdlm_initWithBuilderBlock:^(LynxViewBuilder * _Nonnull innerBuilder) {
                !block ?: block(innerBuilder);
            [innerBuilder.config registerModule:moduleClass param:@{@"containerID" : weakSelf.bdlm_containerID}];
        }];
        if(obj) {
            [obj addLifecycleClient:[IESLynxMonitor sharedMonitor]];
            [[IESLynxMonitor sharedMonitor] trackStart:obj];
            Class monitorPoolClass = NSClassFromString(@"BDLynxMonitorPool");
            SEL sel = NSSelectorFromString(@"setLynxView:forContainerID:");
            IMP monitorPoolImp = nil;
            if(monitorPoolClass) {
                monitorPoolImp = [monitorPoolClass methodForSelector:sel];
            }
            if(monitorPoolImp) {
                ((void(*)(id, SEL, id, NSString *))monitorPoolImp)(monitorPoolClass, sel, obj, obj.bdlm_containerID);
            }
        }
    } else {
        obj = [self bdlm_initWithBuilderBlock:block];
        if (obj) {
            [obj addLifecycleClient:[IESLynxMonitor sharedMonitor]];
            [[IESLynxMonitor sharedMonitor] trackStart:obj];
        }
    }
    
    [self autoAddBlankDetectIfNeeded];
    [BDWMDeallocHelper attachDeallocBlock:^{
        [weakSelf bdlm_removeContainerId];
    } toTarget:obj forKey:@"bdwm_lynx_rm"];
    return obj;
}

- (void)bdlm_clearForDestroy {
    IESLynxPerformanceDictionary *perfDict = self.performanceDic;
    if (!perfDict.hasReportPerf || [perfDict attachTS] == 0) {
        NSInteger lynxState = [perfDict attachTS] == 0 ? 3 : 2;
        [perfDict coverWithDic:@{kLynxMonitorState : @(lynxState)}];
        [perfDict reportPerformance];
    }
    [self bdlm_clearForDestroy];
}

- (void)bdlm_willMoveToWindow:(UIWindow *)newWindow {
    IESLynxPerformanceDictionary *perfDict = self.performanceDic;
    if (newWindow) { // add
        if (!perfDict.bdlm_hasAttach) {
            [perfDict updateAttachTS:[IESLiveMonitorUtils formatedTimeInterval]];
            perfDict.bdlm_hasAttach = YES;
        }
    } else { // remove
        if (perfDict.bdlm_hasAttach) {
            [perfDict updateDetachTS:[IESLiveMonitorUtils formatedTimeInterval]]; ;
            perfDict.bdlm_hasAttach = NO;
        }
    }
    [self bdlm_willMoveToWindow:newWindow];
}

- (void)autoAddBlankDetectIfNeeded {
    NSMutableDictionary *settingMap = [IESLynxMonitor sharedMonitor].classSettingMap;
    IESLiveDefaultSettingModel *model = nil;
    if (settingMap) {
        for (NSString *className in settingMap.allKeys) {
            if ([self isKindOfClass:NSClassFromString(className)]) {
                model = [settingMap objectForKey:className];
            }
        }
    }
    if (model) {
        SEL sel = NSSelectorFromString(@"switchOnAutoCheckBlank:lynxView:");
        if ([self respondsToSelector:sel]) {
            IMP imp = [self methodForSelector:sel];
            if (imp) {
                void (*func)(id,SEL,BOOL,LynxView *) = (void *)imp;
                func(self,sel,model.turnOnLynxBlankMonitor,self);
            }
        }
    }
}

- (void)bdlm_removeContainerId {
    Class monitorPoolClass = NSClassFromString(@"BDLynxMonitorPool");
    SEL sel = NSSelectorFromString(@"removeforContainerID:");
    IMP imp = nil;
    if(monitorPoolClass) {
        imp = [monitorPoolClass methodForSelector:sel];
    }
    if(imp && self.bdlm_containerID.length > 0) {
        ((id(*)(id, SEL, NSString *))imp)(monitorPoolClass, sel, self.bdlm_containerID);
    }
}

//- (void)bdlm_removeFromSuperview {
//    if (self.config) {
//        [[IESLynxMonitor sharedMonitor] trackLynxService:@"lynx_overview_service" status:0 duration:0 extra:@{} config:self.config lynxView:self];
//    }
//
//    [self bdlm_removeFromSuperview];
//}

@end
