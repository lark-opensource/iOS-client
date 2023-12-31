//
//  OPNoticeManager.m
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/8/9.
//

#import "OPNoticeManager.h"
#import "OPNoticeModel.h"
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPCommonManager.h>
#import "BDPTaskManager.h"
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/BDPUserPluginDelegate.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import "BDPAppContainerController.h"

@interface OPNoticeManager()

/// key: uuid , value failuretime， 记录小程序显示状态，用于存到本地缓存，仅首次打开 需用到该状态
@property (nonatomic,strong) NSMutableDictionary *noticeShownDic;
///文件 锁
@property (nonatomic, strong) NSLock *noticeShownLock;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation OPNoticeManager

static NSString * const kNoticeShownDic = @"tt_notice_show_dic";


#pragma mark - public method

+ (instancetype)sharedManager {
    static OPNoticeManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.noticeShownLock = [[NSLock alloc] init];

    });

    return manager;
}

-(BOOL)shouldShowNoticeViewForModel:(OPNoticeModel *)model{
    
    if (model.display_rule == OPNoticeDisplayRuleFirstTime) {
        if ([self.noticeShownDic.allKeys containsObject:model.uuid]) {
            return false;
        }
        if (![self isValidTimeForModel:model]) {
            return false;
        }
        return true;
    } else if(model.display_rule == OPNoticeDisplayRuleEveryTime){
        if (![self isValidTimeForModel:model]) {
            return false;
        }
        return true;
    }
    BDPLogError(@"notice get invalid display_rule");
    return false;
}

-(void)requsetNoticeModelForAppID:(NSString *)appID context:(id<ECONetworkServiceContext>)context callback:(void(^)(OPNoticeModel *))callback{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        WeakSelf;
        [TTNetworkObjcBridge fetchNoticeBy:context appID:appID completionHandler:^(NSDictionary<NSString *,id> * _Nullable noticeDict, NSError * _Nullable error) {
            StrongSelfIfNilReturn;

            if (error || BDPIsEmptyDictionary(noticeDict)) {
                NSString *msg = error.localizedDescription ?: @"noticeDict is empty";
                BDPLogError(msg);
                return;
            }
            if (BDPIsEmptyDictionary(noticeDict[@"data"]) || BDPIsEmptyDictionary(noticeDict[@"data"][@"notification"])) {
                BDPLogError(@"notification data is empty");
                return ;
            }
            OPNoticeModel *model = [[OPNoticeModel alloc] init];
            [model setValuesForKeysWithDictionary:noticeDict[@"data"][@"notification"]];
            if (callback) {
                callback(model);
            }
        }];
    });

}


///记录打开弹窗
-(void)recordShowNoticeViewForModel:(OPNoticeModel *)model appID:(NSString *)appID {
    [self saveNoticeShowToStorageForModel:model];
    OPMonitorEvent *monitor = [[OPMonitorEvent alloc] initWithService:nil name:@"openplatform_in_app_notification_view"
monitorCode:EPMClientOpenPlatformInAppNotificationCode.openplatform_in_app_notification_view];
    monitor.setPlatform(OPMonitorReportPlatformTea | OPMonitorReportPlatformSlardar)
    .addCategoryValue(@"notification_id", model.uuid ?: @"")
    .addCategoryValue(@"application_id",appID ?: @"")
    .flush();
}


///记录关闭弹窗
-(void)recordCloseNoticeViewForModel:(OPNoticeModel *)model appID:(NSString *)appID {
    OPMonitorEvent *monitor = [[OPMonitorEvent alloc] initWithService:nil name:@"openplatform_in_app_notification_click"
monitorCode:EPMClientOpenPlatformInAppNotificationCode.openplatform_in_app_notification_click];
    monitor.setPlatform(OPMonitorReportPlatformTea | OPMonitorReportPlatformSlardar)
    .addCategoryValue(@"notification_id", model.uuid ?: @"")
    .addCategoryValue(@"application_id",appID ?: @"")
    .addCategoryValue(@"click",@"close")
    .addCategoryValue(@"target",@"none")
    .flush();
}


#pragma mark - private method

-(BOOL)isValidTimeForModel:(OPNoticeModel *)model{
    NSDate *effective_date = [self.dateFormatter dateFromString:model.effective_time];
    NSDate *failure_date = [self.dateFormatter dateFromString:model.failure_time];
    NSDate *currentTime = [NSDate date];
    NSTimeInterval toTime = [currentTime timeIntervalSinceDate:effective_date];
    NSTimeInterval fromTime = [currentTime timeIntervalSinceDate:failure_date];
    return (toTime > 0 && fromTime < 0);
}

-(void)saveNoticeShowToStorageForModel:(OPNoticeModel *)model{
    if (BDPIsEmptyString(model.uuid) || BDPIsEmptyString(model.failure_time)) {
        BDPLogError(@"uuid or failure_time is empty");
        return ;
    }
    if ([self.noticeShownDic.allKeys containsObject:model.uuid] || model.display_rule == OPNoticeDisplayRuleEveryTime) {
        BDPLogInfo(@"uuid have saved or uuid need show everytime");
        return ;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        [self.noticeShownLock lock];
        [self.noticeShownDic setObject:model.failure_time forKey:model.uuid];
        TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
        [storage setObject:self.noticeShownDic forKey:kNoticeShownDic];
        [self.noticeShownLock unlock];
    });
}

-(NSMutableDictionary *)noticeShownDic{
    if (!_noticeShownDic) {
        TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
        NSDictionary *noticeShowStorageDic = [storage objectForKey:kNoticeShownDic];
        if (!noticeShowStorageDic) {
            _noticeShownDic = [NSMutableDictionary new];
        } else {
            _noticeShownDic = [[NSMutableDictionary alloc] initWithDictionary:noticeShowStorageDic];
            [self deleteExpiredKeyForDic:_noticeShownDic];
        }
    }
    return _noticeShownDic;
}

-(void)deleteExpiredKeyForDic:(NSMutableDictionary *)dic{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        [self.noticeShownLock lock];
        NSMutableArray *deletedKeys = [NSMutableArray new];
        for (NSString *key in dic) {
            NSDate *failure_date = [self.dateFormatter dateFromString:dic[key]];
            NSDate *currentTime = [NSDate date];
            NSTimeInterval fromTime = [currentTime timeIntervalSinceDate:failure_date];
            if (fromTime > 0) {
                [deletedKeys addObject:key];
            }
        }
        if(BDPIsEmptyArray(deletedKeys)){
            [self.noticeShownLock unlock];
            return  ;
        }
        [dic removeObjectsForKeys:deletedKeys];
        TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
        [storage setObject:dic forKey:kNoticeShownDic];
        [self.noticeShownLock unlock];
    });
}

- (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] objectAtIndex:0]];  // 获得正确的返回日期，避免日本日历、佛教日历取date异常
        [dateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];  // 选择公历
    });
    return dateFormatter;
}


@end
