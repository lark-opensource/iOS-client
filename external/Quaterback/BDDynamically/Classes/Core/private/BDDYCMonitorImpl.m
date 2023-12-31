//
//  BDDYCMonitor.m
//  BDDynamically
//
//  Created by hopo on 2019/1/31.
//

#import "BDDYCMonitorImpl.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "BDBDQuaterback+Internal.h"
#import "BDBDQuaterback.h"

NSString *const kBDDYCQuaterbackMonitorLogType = @"bd_better_monitor";
NSString *const kBDDYQuaterbackListDownloadStatusMonitorServiceName = @"bd_better_list_download_status_monitor";
NSString *const kBDDYCQuaterbackDidClearOldVersionQuaterbacksMonitorServiceName = @"bd_better_clear_old_version_monitor";
NSString *const kBDDYCQuaterbackWillClearQuaterbacksMonitorServiceName = @"bd_better_will_clear_monitor";
NSString *const kBDDYCQuaterbackEncryptedTime = @"bd_better_en_time_monitor";
NSString *const kBDDYCQuaterbackUnzipTime = @"bd_better_unzip_time_monitor";
NSString *const kBDDYCQuaterbackDownloadZipTime = @"bd_better_download_zip_time_monitor";
NSString *const kBDDYCQuaterbackDAU = @"bd_better_load_success";
NSString *const kBDDYCQuaterbackDownloadStart = @"bd_better_download_start";
NSString *const kBDDYCQuaterbackDownloadend = @"bd_better_download_end";

NSString *const kBDDYCQuaterbackInjectedInfoKey = @"bdd_better_custom_Info";

@implementation BDDYCMonitorImpl

+ (void)trackData:(NSDictionary *)data
       logTypeStr:(NSString *)logType {
    id shareInstance = [self monitorInstance];
//    hmdTrackService
    SEL trackSel = NSSelectorFromString(@"trackData:logTypeStr:");
    SEL hmdTtrackSel = NSSelectorFromString(@"hmdTrackData:logTypeStr:");
    if (hmdTtrackSel) {
        trackSel = hmdTtrackSel;
    }
    if (shareInstance && trackSel && [shareInstance respondsToSelector:trackSel]) {
        void (*action)(id, SEL, NSDictionary*, NSString*) =(void (*)(id, SEL, NSDictionary*, NSString*))objc_msgSend;
        action(shareInstance, trackSel, data, logType);
    }
}

+ (void)trackData:(NSDictionary *)data {
    [self trackData:data logTypeStr:kBDDYCQuaterbackMonitorLogType];
}

+ (void)trackService:(NSString *)serviceName
              status:(NSInteger)status
               extra:(NSDictionary *)extraValue {
    
    NSDictionary *category = @{@"status":@(status)};
    [self trackService:serviceName metric:nil category:category extra:extraValue];
}

+ (void)trackService:(nonnull NSString *)serviceName metric:(nullable NSDictionary <NSString *, NSNumber *> *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extraValue {
    id monitorManager = [self monitorManager];

//    NSDictionary *metric = @{@"duration":@(durations)};
    SEL trackSel = NSSelectorFromString(@"hmdTrackService:metric:category:extra:");
    if (monitorManager && trackSel && [monitorManager respondsToSelector:trackSel]) {
        void (*action)(id, SEL, NSString*, NSDictionary*, NSDictionary*, NSDictionary*) =(void (*)(id, SEL, NSString*, NSDictionary*, NSDictionary*, NSDictionary*))objc_msgSend;
        action(monitorManager, trackSel, serviceName, metric,category,extraValue);
    }

    id shareInstance = [self monitorInstance];
    if (shareInstance && trackSel && [shareInstance respondsToSelector:trackSel]) {
        void (*action)(id, SEL, NSString*, NSDictionary*, NSDictionary*, NSDictionary*) =(void (*)(id, SEL, NSString*, NSDictionary*, NSDictionary*, NSDictionary*))objc_msgSend;
        action(shareInstance, trackSel, serviceName, metric,category,extraValue);
    }
}


+ (void)event:(NSString *)type label:(NSString *)label durations:(float)durations needAggregate:(BOOL)needAggr {
    id shareInstance = [self monitorInstance];

    NSDictionary *metric = @{@"duration":@(durations)};
    SEL trackSel = NSSelectorFromString(@"hmdTrackService:metric:category:extra:");
    if (shareInstance && trackSel && [shareInstance respondsToSelector:trackSel]) {
        void (*action)(id, SEL, NSString*, NSDictionary*, NSDictionary*, NSDictionary*) =(void (*)(id, SEL, NSString*, NSDictionary*, NSDictionary*, NSDictionary*))objc_msgSend;
        action(shareInstance, trackSel, type, metric,nil,nil);
    }
}

+ (void)setCustomFilterValue:(id)value forKey:(NSString *)key {
    id shareInstance = [self inJectedInfoInstance];
    SEL trackSel = NSSelectorFromString(@"setCustomFilterValue:forKey:");
    if (shareInstance && trackSel && [shareInstance respondsToSelector:trackSel]) {
        void (*action)(id, SEL, id, NSString*) =(void (*)(id, SEL, id, NSString*))objc_msgSend;
        action(shareInstance, trackSel, value, key);
    }
}

+ (void)setCustomContextValue:(id)value forKey:(NSString *)key {
    id shareInstance = [self inJectedInfoInstance];
    SEL trackSel = NSSelectorFromString(@"setCustomContextValue:forKey:");
    if (shareInstance && trackSel && [shareInstance respondsToSelector:trackSel]) {
        void (*action)(id, SEL, id, NSString*) =(void (*)(id, SEL, id, NSString*))objc_msgSend;
        action(shareInstance, trackSel, value, key);
    }
}

+ (void)removeCustomFilterKey:(NSString *)key {
    id shareInstance = [self inJectedInfoInstance];
    SEL trackSel = NSSelectorFromString(@"removeCustomFilterKey:");
    if (shareInstance && trackSel && [shareInstance respondsToSelector:trackSel]) {
        void (*action)(id, SEL, NSString*) =(void (*)(id, SEL, NSString*))objc_msgSend;
        action(shareInstance, trackSel, key);
    }
}

+ (id)inJectedInfoInstance {
    //通过TTMonitor上报log
    Class cls = NSClassFromString(@"HMDInjectedInfo");
    SEL shareInstanceSel = NSSelectorFromString(@"defaultInfo");
    id shareInstance = nil;
    if (cls && shareInstanceSel && [cls respondsToSelector:shareInstanceSel]) {
        id (*action)(Class, SEL) = (id (*)(Class, SEL))objc_msgSend;
        shareInstance = action(cls, shareInstanceSel);
    }
    return shareInstance;
}

+ (id)monitorManager {
    NSString *aid = @"2559";
    NSString *hostAppID = [BDBDQuaterback sharedMain].conf.aid;
    NSString *did = [BDBDQuaterback sharedMain].conf.deviceId;
    NSString *channel = [BDBDQuaterback sharedMain].conf.channel;
    BOOL enableBackgroundUpload = YES;
    Class cls = NSClassFromString(@"HMDTTMonitor");
    Class injectedInfoCls = NSClassFromString(@"HMDTTMonitorUserInfo");
    SEL allocSel = NSSelectorFromString(@"alloc");
    SEL monitorSel = NSSelectorFromString(@"initMonitorWithAppID:injectedInfo:");
    SEL injectedInfoSel = NSSelectorFromString(@"initWithAppID:");
    SEL setAppIDSel = NSSelectorFromString(@"setAppID:");
    SEL setDidSel = NSSelectorFromString(@"setDeviceID:");
    SEL setHostAppIDSel = NSSelectorFromString(@"setHostAppID:");
    SEL setChannelSel = NSSelectorFromString(@"setChannel:");
    SEL setEnableBackgroundUploadSel = NSSelectorFromString(@"setEnableBackgroundUpload:");

    id allocInstance = nil;
    id monitorManager = nil;
    id injectedInfo = nil;
    id injectedAlloc = nil;
    if (injectedInfoCls && allocSel && [injectedInfoCls respondsToSelector:allocSel]) {
        id (*action)(Class, SEL) = (id (*)(Class, SEL))objc_msgSend;
        injectedAlloc = action(injectedInfoCls, allocSel);

        if (injectedAlloc && injectedInfoSel && [injectedAlloc respondsToSelector:injectedInfoSel]) {
            id (*action)(id, SEL, NSString*) = (id (*)(id, SEL, NSString*))objc_msgSend;
            injectedInfo = action(injectedAlloc, injectedInfoSel, aid);

            if (injectedInfo && setAppIDSel && [injectedInfo respondsToSelector:setAppIDSel]) {
                void (*action)(id, SEL, NSString*) = (void (*)(id, SEL, NSString*))objc_msgSend;
                action(injectedInfo, setAppIDSel, aid);
            }

            if (injectedInfo && setDidSel && [injectedInfo respondsToSelector:setDidSel]) {
                void (*action)(id, SEL, NSString*) = (void (*)(id, SEL, NSString*))objc_msgSend;
                action(injectedInfo, setDidSel, did);
            }

            if (injectedInfo && setHostAppIDSel && [injectedInfo respondsToSelector:setHostAppIDSel]) {
                void (*action)(id, SEL, NSString*) = (void (*)(id, SEL, NSString*))objc_msgSend;
                action(injectedInfo, setHostAppIDSel, hostAppID);
            }

            if (injectedInfo && setChannelSel && [injectedInfo respondsToSelector:setChannelSel]) {
                void (*action)(id, SEL, NSString*) = (void (*)(id, SEL, NSString*))objc_msgSend;
                action(injectedInfo, setChannelSel, channel);
            }

            if (injectedInfo && setEnableBackgroundUploadSel && [injectedInfo respondsToSelector:setEnableBackgroundUploadSel]) {
                void (*action)(id, SEL, BOOL) = (void (*)(id, SEL, BOOL))objc_msgSend;
                action(injectedInfo, setEnableBackgroundUploadSel, enableBackgroundUpload);
            }

        }
    }
    if (cls && allocSel && [cls respondsToSelector:allocSel]) {
        id (*action)(Class, SEL) = (id (*)(Class, SEL))objc_msgSend;
        allocInstance = action(cls, allocSel);
    }
    if (allocInstance && monitorSel && [allocInstance respondsToSelector:monitorSel]) {
        id (*action)(id, SEL, NSString*, id) = (id (*)(id, SEL, NSString*, id))objc_msgSend;
        monitorManager = action(allocInstance, monitorSel, aid, injectedInfo);
    }
    return monitorManager;
}


+ (id)monitorInstance {
    //通过TTMonitor上报log
    Class cls = NSClassFromString(@"TTMonitor");
    Class hmdCls = NSClassFromString(@"HMDTTMonitor");
    SEL shareInstanceSel = NSSelectorFromString(@"shareManager");
    if (hmdCls) {
        cls = hmdCls;
        shareInstanceSel = NSSelectorFromString(@"defaultManager");
    }
    id shareInstance = nil;
    if (cls && shareInstanceSel && [cls respondsToSelector:shareInstanceSel]) {
        id (*action)(Class, SEL) = (id (*)(Class, SEL))objc_msgSend;
        shareInstance = action(cls, shareInstanceSel);
    }
    return shareInstance;
}


@end

id<BDBDMonitorClass> BDDYCMonitorGet(void)
{
    if ([BDBDQuaterback sharedMain].conf.monitor) {
        return [BDBDQuaterback sharedMain].conf.monitor;
    }
    return (id<BDBDMonitorClass>)[BDDYCMonitorImpl class];
}
