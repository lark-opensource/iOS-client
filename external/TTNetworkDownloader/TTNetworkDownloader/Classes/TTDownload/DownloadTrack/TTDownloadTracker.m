//
//  TTDownloadTracker.m
//  TTNetworkDownloader
//
//  Created by Nami on 2020/3/4.
//

#import "TTDownloadTracker.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TTDownloadTracker

+ (instancetype)sharedInstance {
    static TTDownloadTracker *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TTDownloadTracker alloc] init];
    });
    return instance;
}

- (int64_t)deviceAvailableSpace {
    NSError *error = nil;
    NSString *dirPath = NSTemporaryDirectory();

    if (@available(iOS 11.0, *)) {
        NSURL *fileUrl = [NSURL fileURLWithPath:dirPath];
        NSNumber *freeSpace = nil;
        [fileUrl getResourceValue:&freeSpace forKey:NSURLVolumeAvailableCapacityForImportantUsageKey error:&error];
        if (freeSpace && !error) {
            return [freeSpace longLongValue];
        }
    }

    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:dirPath error:&error];
    if (dictionary && !error) {
        return [dictionary[NSFileSystemFreeSize] longLongValue];
    }
    return -1;
}

- (NSString *)eventNameWithEvent:(TTDownloadEvent)event {
    NSString *eventName = @"";
    switch (event) {
        case TTDownloadEventFailed:
            eventName = @"download_failed";
            break;
        default:
            eventName = @"download_common";
            break;
    }

    return eventName;
}

- (NSString *)statusWithCommonEvent:(TTDownloadEvent)event {
    NSString *status = @"";
    switch (event) {
        case TTDownloadEventCreate:
            status = @"download_create";
            break;
        case TTDownloadEventFirstStart:
            status = @"download_first_start";
            break;
        case TTDownloadEventStart:
            status = @"download_start";
            break;
        case TTDownloadEventPause:
            status = @"download_pause";
            break;
        case TTDownloadEventFinish:
            status = @"download_success";
            break;
        case TTDownloadEventCancel:
            status = @"download_cancel";
            break;
        case TTDownloadEventUncompleted:
            status = @"download_uncomplete";
            break;
        default:
            break;
    }

    return status;
}

- (void)sendFinishEventWithModel:(TTDownloadTrackModel *)model {
    model.trackStatus = TRACK_FINISH;
    [model addDownloadTimeWithReSet];

    if (model.totalBytes > 0 && model.downloadTime > 0) {
        model.downloadSpeed = (model.totalBytes / 1024.0 / 1024.0) / (model.downloadTime / 1000.0);
    }

    if (model.isBgDownloadEnable) {
        [model calBgDownloadBytes];
    }

    [self sendEvent:TTDownloadEventFinish eventModel:model];
}

- (void)sendCancelEventWithModel:(TTDownloadTrackModel *)model {
    model.trackStatus = TRACK_CANCEL;
    [model addDownloadTimeWithReSet];
    [self sendEvent:TTDownloadEventCancel eventModel:model];
}

- (void)sendFailEventWithModel:(TTDownloadTrackModel *)model failCode:(NSInteger)code failMsg:(NSString *)msg {
    model.failStatus = code;
    model.failMsg = msg;
    model.trackStatus = TRACK_FAIL;
    [model addDownloadTimeWithReSet];
    [self sendEvent:TTDownloadEventFailed eventModel:model];
}

- (void)sendUncompleteEventWithModel:(TTDownloadTrackModel *)model {
    model.trackStatus = TRACK_UNCOMPLETED;
    [self sendEvent:TTDownloadEventUncompleted eventModel:model];
}

- (void)sendEvent:(TTDownloadEvent)event eventModel:(TTDownloadTrackModel *)model {
    if (!self.eventBlock || !model) {
        return;
    }

    NSString *eventName = [self eventNameWithEvent:event];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];

    if (model.extraParams) {
        [params setValuesForKeysWithDictionary:model.extraParams];
    }

    if (event == TTDownloadEventFailed) {
        params[@"status"] = @(model.failStatus);
        params[@"error_msg"] = model.failMsg;
    } else {
        params[@"status"] = [self statusWithCommonEvent:event];
    }

    params[@"download_id"] = model.downloadId ? model.downloadId : @"";
    params[@"url"] = model.url;
    params[@"name"] = model.name ? model.name : @"";
    params[@"event_page"] = @"";

    NSURL *URL = [NSURL URLWithString:model.url];
    NSString *urlPath = [[URL URLByDeletingLastPathComponent] path];
    params[@"url_host"] = [URL host] ? [URL host] : @"";
    params[@"url_path"] = urlPath ? urlPath : @"";
    params[@"url_last_path_segment"] = [URL lastPathComponent] ? [URL lastPathComponent] : @"";

    params[@"device_id_postfix"] = @"";
    params[@"only_wifi"] = @(model.isWifiOnly);
    params[@"retry_count"] = @(model.retryCount * model.sliceCount);
    params[@"cur_retry_time"] = @(model.curRetryTime);
    params[@"cur_bytes"] = @(model.curBytes);
    params[@"total_bytes"] = @(model.totalBytes);

    params[@"md5"] = model.md5Value ? model.md5Value : @"";
    params[@"md5_time"] = @(model.md5Time);

    params[@"chunk_count"] = @(model.sliceCount);

    params[@"download_time"] = @(model.downloadTime);
    params[@"second_url"] = model.secondUrl ? model.secondUrl : @"";

    params[@"url_retry_count"] = @(model.urlRetryCount);
    params[@"cur_url_retry_time"] = @(model.curUrlRetryTime);
    params[@"url_retry_interval"] = @(model.urlRetryInterval);
    params[@"gcl_time"] = @(model.gclTime);

    params[@"retry_interval"] = @(model.retryInterval);
    params[@"retry_interval_incrememt"] = @(model.retryIntervalIncrement);

    params[@"download_speed"] = @(model.downloadSpeed);

    params[@"throttle_net_speed"] = @(model.throttleNetSpeed);

    params[@"slice_merge_time"] = @(model.sliceMergeTime);

    params[@"background_download_enable"] = @(model.isBgDownloadEnable);
    params[@"background_download_finish"] = @(model.isBackgroundDownloadFinish);
    params[@"background_download_time"] = @(model.bgDownloadTime);
    params[@"background_download_bytes"] = @(model.curBgDownloadBytes);

    params[@"device_available_space"] = @([self deviceAvailableSpace]);

    params[@"need_https_degrade"] = @(model.httpsDegradeEnable);
    params[@"https_degrade_retry_used"] = @(model.hasHttpsDegrade);

    params[@"restore_count"] = @(model.restoreCount);
    params[@"cur_restore_time"] = @(model.curRestoreTime);

    self.eventBlock(eventName, params.copy);
}

@end

NS_ASSUME_NONNULL_END
