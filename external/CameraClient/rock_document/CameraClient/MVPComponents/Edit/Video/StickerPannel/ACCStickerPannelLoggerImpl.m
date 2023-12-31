//
//  ACCStickerPannelLoggerImpl.m
//  Pods
//
//  Created by liyingpeng on 2020/8/4.
//

#import "AWERepoPropModel.h"
#import "ACCStickerPannelLoggerImpl.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import "AWESingleStickerDownloader.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import "ACCConfigKeyDefines.h"
#import "AWERepoTrackModel.h"
#import <EffectPlatformSDK/IESInfoStickerModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCENVProtocol.h>

@implementation ACCStickerPannelLoggerImpl

- (void)logStickerDownloadFinished:(AWESingleStickerDownloadInfo *)downloadInfo {
    NSError *error = downloadInfo.result.error;
    NSString *filePath = downloadInfo.result.filePath;
    
    NSString *downloadUrl = downloadInfo.fileDownloadURLs ? [downloadInfo.fileDownloadURLs componentsJoinedByString:@";"] : downloadInfo.stickerUrl;
    NSDictionary *extraInfo = @{
                                @"info_sticker_id" : downloadInfo.effectIdentifier ?: @"",
                                @"info_sticker_name" : downloadInfo.effectName ?: @"",
                                @"download_urls" : downloadUrl ?: @""
                                };
    
    if (error || ACC_isEmptyString(filePath)) {
        [ACCMonitor() trackService:@"aweme_info_sticker_platform_download_error"
                                 status:1
                                  extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                      @"errorCode" : @(error.code),
                                      @"errorDesc" : error.localizedDescription ?: @""
                                  }]];
    } else {
        [ACCMonitor() trackService:@"aweme_info_sticker_platform_download_error"
                                 status:0
                                  extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                      @"duration" : @(downloadInfo.duration)
                                  }]];
    }
    
    NSInteger success = !(error || ACC_isEmptyString(filePath));
    
    NSMutableDictionary *params = @{@"resource_type":@"info_effect",
                                    @"resource_id":downloadInfo.effectIdentifier?:@"",
                                    @"duration":@(downloadInfo.duration),
                                    @"status":@(success?0:1),
                                    @"error_domain":error.domain?:@"",
                                    @"error_code":@(error.code)}.mutableCopy;
    [params addEntriesFromDictionary:self.repository.repoTrack.commonTrackInfoDic?:@{}];
    [ACCTracker() trackEvent:@"tool_performance_resource_download"
                       params:params.copy
              needStagingFlag:NO];
}

- (void)logPannelUpdateFailed:(NSString *)pannelName
               updateDuration:(CFAbsoluteTime)duration {
    [ACCMonitor() trackService:@"aweme_effect_list_error" status:30 extra:@{
        @"panel" : pannelName ?: @"",
        @"duration" : @(duration * 1000),
        @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
        @"needUpdate" : @(NO)
     }];
}

- (void)logStickerWillDisplay:(NSString *)stickerIdentifier categoryId:(NSString *)categoryId categoryName:(NSString *)categoryName {
    NSMutableDictionary *dict = [self.repository.repoTrack.referExtra mutableCopy];
    [dict addEntriesFromDictionary:@{
                                     @"prop_id" : stickerIdentifier ? : @"",
                                     @"enter_method" : @"click_main_panel",
                                     @"category_name" : categoryName ? : @"",
                                     @"tab_id" : categoryId ? :@"",
                                     @"is_giphy" : @(0)
                                     }];
    if (!ACC_isEmptyString(self.repository.repoProp.localPropId)) {
        dict[@"from_prop_id"] = self.repository.repoProp.localPropId;
    }
    if (self.repository.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
        [ACCTracker() trackEvent:@"prop_show" params:dict needStagingFlag:NO];
    }
}

- (void)logBottomBarDidSelectCategory:(NSString *)categoryName pannelTab:(NSString *)tabName {
    [ACCTracker() trackEvent:@"click_infosticker_tab"
             params:@{
                 @"creation_id" : self.repository.repoContext.createId ? : @"",
                 @"shoot_way" : self.repository.repoTrack.referString ? : @"",
                 @"content_type" : self.repository.repoTrack.referExtra[@"content_type"] ? : @"",
                 @"content_source" : self.repository.repoTrack.referExtra[@"content_source"] ? : @"",
                 @"enter_from" : @"video_edit_page",
                 @"category_name" : tabName ? : @"",
                 @"tab_name" : categoryName ? : @"",
             }
    needStagingFlag:NO];
}

- (void)logPannelUpdateFinished:(NSString *)pannelName needUpdate:(BOOL)needUpdate updateDuration:(CFAbsoluteTime)duration success:(BOOL)success error:(nullable NSError *)error {
    if (success) {
        [ACCMonitor() trackService:@"aweme_effect_list_error"
                                 status:30
                                  extra:@{
                                      @"panel" : pannelName ?: @"",
                                      @"duration" : @(duration * 1000),
                                      @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                      @"needUpdate" : @(YES)
                                  }];
    } else {
        [ACCMonitor() trackService:@"aweme_effect_list_error"
                                 status:31
                                  extra:@{
                                      @"panel" : pannelName ?: @"",
                                      @"errorDesc" : error.description ?: @"",
                                      @"errorCode" : @(error.code),
                                      @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                      @"needUpdate" : @(needUpdate)
                                  }];
    }
    
    NSMutableDictionary *params = @{@"api_type":@"info_effect_list",
                                    @"duration":@(duration * 1000),
                                    @"status":@(success ? 0 : 1),
                                    @"error_domain":error.domain ?: @"",
                                    @"error_code":@(error.code)}.mutableCopy;
    [params addEntriesFromDictionary:self.repository.repoTrack.commonTrackInfoDic ?: @{}];
    [ACCTracker() trackEvent:@"tool_performance_api" params:params.copy needStagingFlag:NO];
    // saf test
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCENVProtocol) currentEnv] == ACCENVSaf) {
        NSMutableDictionary *metricExtra = @{}.mutableCopy;
        UInt64 end_time = (UInt64)([[NSDate date] timeIntervalSince1970] * 1000);
        UInt64 start_time = end_time - (UInt64)(duration);
        [metricExtra addEntriesFromDictionary:@{@"metric_name": @"duration", @"start_time": @(start_time), @"end_time": @(end_time)}];
        params[@"metric_extra"] = @[metricExtra];
        [ACCTracker() trackEvent:@"tool_performance_info_effect_list_saf" params:params.copy needStagingFlag:NO];
    }
}

- (void)logSlidingDidSelectIndex:(NSInteger)index title:(nullable NSString *)title {
    if (self.repository.repoContext.recordSourceFrom == AWERecordSourceFromIM ||
        self.repository.repoContext.recordSourceFrom == AWERecordSourceFromIMGreet) {
        return;
    }
    NSMutableDictionary *dict = [self.repository.repoTrack.referExtra mutableCopy];
    [dict addEntriesFromDictionary:@{@"tab_name" : title ? : @""}];
    [ACCTracker() trackEvent:@"click_prop_tab" params:dict needStagingFlag:NO];
}

- (void)logStickerPannelDidSelectSticker:(NSString *)stickerIdentifier index:(NSInteger)index tab:(NSString *)tabName categoryName:(NSString *)categoryName extra:(nullable NSDictionary *)extra{
    NSMutableDictionary *dict = [self.repository.repoTrack.referExtra mutableCopy];
    [dict addEntriesFromDictionary:@{
                                     @"impr_position": @(index+1).stringValue,
                                     @"after_search": @"0",
                                     @"prop_id" : stickerIdentifier ? : @"",
                                     @"tab_id" : tabName ? : @"",
                                     @"category_name" : categoryName ? : @"",
                                     @"is_giphy" : @(0),
                                     }];
    if (extra) {
        [dict addEntriesFromDictionary:extra];
    }
    dict[@"from_parent_id"] = self.repository.repoUploadInfo.extraDict[@"from_parent_id"];
    dict[@"is_groot_new"] = self.repository.repoUploadInfo.extraDict[@"is_groot_new"];
    BOOL grootShow = [ACCCache() boolForKey:@"kAWENormalVideoEditGrootStickerBubbleShowKey"];
    dict[@"is_groot_toast_show"]  = grootShow ? @1 : @0;
    dict[@"staus"] = self.repository.repoTrack.enterStatus?:@"";
    if (self.repository.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
        [ACCTracker() trackEvent:@"prop_click" params:dict needStagingFlag:NO];
    }
}

@end
