//
//  BDAutoTrackSettingsRequest.m
//  RangersAppLog
//
//  Created by bob on 2019/9/15.
//




#import "BDAutoTrackSettingsRequest.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackMacro.h"
#import "BDAutoTrackBatchService.h"
#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackServiceCenter.h"

#import "BDAutoTrackDeviceHelper.h"
#import "NSDictionary+VETyped.h"
#import "NSData+VECryptor.h"
#import "NSData+VECompression.h"
#import "BDAutoTrack+Private.h"

static NSString * const kBDTrackerLastFetchTime = @"kBDTrackerLastFetchTime";

@interface BDAutoTrackSettingsRequest ()

@end

@implementation BDAutoTrackSettingsRequest

- (instancetype)initWithAppID:(NSString *)appID next:(BDAutoTrackRequest *)nextRequest {
    self = [super initWithAppID:appID next:nextRequest];
    if (self) {
        self.requestType = BDAutoTrackRequestURLSettings;
        self.lastFetchTime = 0;
    }

    return self;
}

- (NSString *)requestURL {
    NSString *url = [super requestURL];
    return bd_appendQueryToURL(url, kBDAutoTrackDecivcePlatform, bd_device_platformName());
}

/// 限制频率
- (void)startRequestWithRetry:(NSInteger)retry {
    long long fetchInterval = bd_remoteSettingsForAppID(self.appID).fetchInterval;
    long long now = [[NSDate date] timeIntervalSince1970];
    if (now < self.lastFetchTime + fetchInterval) {
        return;
    }
    self.lastFetchTime = now;
    [super startRequestWithRetry:retry];
}

- (BOOL)handleResponse:(NSDictionary *)responseDict urlResponse:(NSURLResponse *)urlResponse request:(nonnull NSDictionary *)request {
    BOOL success = bd_isValidResponse(responseDict);
    if (success) {
        long long now = [[NSDate date] timeIntervalSince1970];
        self.lastFetchTime = now;
        [[BDAutoTrackDefaults defaultsWithAppID:self.appID] setValue:@(now) forKey:kBDTrackerLastFetchTime];
        NSString *appID = self.appID;
        BDAutoTrackRemoteSettingService *settings = bd_remoteSettingsForAppID(appID);
        [settings updateRemoteWithResponse:responseDict];
        bd_batchUpdateTimer(settings.batchInterval, settings.skipLaunch, appID);
        [[BDAutoTrack trackWithAppID:self.appID].localConfig updateServerTime:responseDict];
    } else {
        self.lastFetchTime = 0;
        [[BDAutoTrackDefaults defaultsWithAppID:self.appID] setValue:@(0) forKey:kBDTrackerLastFetchTime];
    }
    /// 不重试
    return YES;
}

- (NSMutableDictionary *)requestParameters {
    NSMutableDictionary *result = [super requestParameters];
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    BDAutoTrackNetworkEncryptor *encryptor = tracker.networkManager.encryptor;
    if (encryptor.encryption) {
        [encryptor addIV:result];
    }
    
    if (tracker.localConfig.eventFilterEnabled) {
        [result setValue:@(1) forKey:@"event_filter"];
    }
    
    return result;
}

- (NSDictionary *)responseFromData:(NSData *)data error:(NSError *)error {
    NSDictionary *result = nil;
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    BDAutoTrackNetworkEncryptor *encryptor = tracker.networkManager.encryptor;
    if (encryptor.encryption) {
        if (data != nil && error == nil) {
            result = [encryptor decryptResponse:data];
        }
    }
    
    /* result == nil:
     * either the encrypt switch is not enabled or
     * the decryption fails (possibly the back data is not encrypted)
     */
    if (result == nil) {
        result = [super responseFromData:data error:error];
    }
    NSString *appID = self.appID;
    if ([BDAutoTrack trackWithAppID:self.appID].localConfig.eventFilterEnabled) {
        NSDictionary *eventList = [[result vetyped_dictionaryForKey:@"config"] vetyped_dictionaryForKey:@"event_list"];
        id<BDAutoTrackFilterService> service = (id<BDAutoTrackFilterService>)bd_standardServices(BDAutoTrackServiceNameFilter, appID);
        [service updateBlockList:eventList save:YES];
    }
    
    
    return result;
}


@end
