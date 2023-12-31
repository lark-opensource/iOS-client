//
//  TSPKEventData.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/19.
//

#import "TSPKEventData.h"
#import "TSPKUtils.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKAppLifeCycleObserver.h"

@implementation TSPKEventData

- (instancetype)init
{
    if (self = [super init]) {
        _subEvents = [NSMutableArray array];
        _timestamp = [TSPKUtils getRelativeTime];
        _unixTimestamp = [TSPKUtils getUnixTime];
        _serverTimestamp = [TSPKUtils getServerTime];
        _lastEnterBackgroundTimestamp = [[TSPKAppLifeCycleObserver sharedObserver] getTimeLastDidEnterBackground];
        _warningTypes = [NSMutableArray array];
        _ruleExecuteResults = [NSMutableArray array];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    TSPKEventData *newEventData = [[[self class] allocWithZone:zone] init];
    newEventData.apiModel = self.apiModel;
    newEventData.matchedRuleId = self.matchedRuleId;
    newEventData.matchedRuleType = self.matchedRuleType;
    newEventData.matchedRuleName = self.matchedRuleName;
    newEventData.matchedRuleParams = self.matchedRuleParams;
    newEventData.unreleaseAddress = self.unreleaseAddress;
    newEventData.isGrayScaleRule = self.isGrayScaleRule;
    newEventData.timeGapToDetect = self.timeGapToDetect;
    newEventData.extraInfo = self.extraInfo;
    newEventData.extraInfoDic = self.extraInfoDic.copy;
    newEventData.subEvents = self.subEvents;
    newEventData.warningTypes = self.warningTypes;
    newEventData.storeIdentifier = self.storeIdentifier;
    newEventData.storeType = self.storeType;
    newEventData.fuseModel = self.fuseModel;
    newEventData.timeDelay = self.timeDelay;
    newEventData.detectTime = self.detectTime;
    newEventData.totalDetectTime = self.totalDetectTime;
    newEventData.timeLastDidEnterBackground = self.timeLastDidEnterBackground;
    newEventData.timeLastWillEnterForeground = self.timeLastWillEnterForeground;
    newEventData.topPageName = self.topPageName;
    newEventData.appStatus = self.appStatus;
    newEventData.timestamp = self.timestamp;
    newEventData.unixTimestamp = self.unixTimestamp;
    newEventData.bpeaContext = self.bpeaContext;
    newEventData.customAnchorCaseId = self.customAnchorCaseId;
    newEventData.customAnchorStartDesc = self.customAnchorStartDesc;
    newEventData.customAnchorStopDesc = self.customAnchorStopDesc;
    newEventData.customAnchorStartTopPage = self.customAnchorStartTopPage;
    newEventData.customAnchorStopTopPage = self.customAnchorStopTopPage;
    newEventData.ruleEngineResult = self.ruleEngineResult;
    newEventData.ruleEngineAction = self.ruleEngineAction;
    newEventData.cacheNeedUpdate = self.cacheNeedUpdate;
    newEventData.ruleExecuteResults = self.ruleExecuteResults;
    return newEventData;
}

- (NSDictionary *)formatDictionary
{
    // copy from FilterDictionary and add extra params
    NSMutableDictionary *dict = [self formatFilterDictionary].mutableCopy;
    
    if (self.timestamp) {
        dict[TSPKEventTimeStampKey] = @(self.timestamp);
    }
    
    if (self.unixTimestamp) {
        dict[TSPKEventUnixTimeStampKey] = @(self.unixTimestamp);
    }
    
    if (self.timeGapToDetect) {
        dict[@"timeGapToDetect"] = @(self.timeGapToDetect);
    }
    
    if (self.apiModel.params[@"status"]) {
        dict[@"status"] = self.apiModel.params[@"status"];
    }
    
    if (self.timeDelay > 0) {
        dict[@"timeDelay"] = @(self.timeDelay);
    }

    if (self.timeLastDidEnterBackground > 0) {
        dict[@"timeLastDidEnterBackground"] = @(self.timeLastDidEnterBackground);
    }

    if (self.timeLastWillEnterForeground > 0) {
        dict[@"timeLastWillEnterForeground"] = @(self.timeLastWillEnterForeground);
    }
    
    if (self.customAnchorStartDesc.length > 0) {
        dict[@"customAnchorStartDesc"] = self.customAnchorStartDesc;
    }

    if (self.customAnchorStopDesc.length > 0) {
        dict[@"customAnchorStopDesc"] = self.customAnchorStopDesc;
    }
    
    if ([self.extraInfo length] > 0) {
        dict[@"extraInfo"] = self.extraInfo;
    }
    
    if (self.extraInfoDic) {
        dict[@"extraInfoDic"] = [TSPKUtils jsonStringEncodeWithObj:self.extraInfoDic];
    }
    
    if (self.matchedRuleParams) {
        dict[@"matchedRuleParams"] = [TSPKUtils jsonStringEncodeWithObj:self.matchedRuleParams];
    }
    
    if (self.unreleaseAddress) {
        dict[@"unreleaseAddress"] = self.unreleaseAddress;
    }

    return [NSDictionary dictionaryWithDictionary:dict];
}

- (NSDictionary *)formatFilterDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if ([self.apiModel.dataType length] > 0) {
        dict[TSPKPermissionTypeKey] = self.apiModel.dataType;
    }

    if ([self.apiModel.apiMethod length] > 0) {
        dict[@"method"] = self.apiModel.apiMethod;
    }

    if ([[TSPKUtils version] length] > 0) {
        dict[@"kitVerison"] = [TSPKUtils version];
    }

    if (self.matchedRuleId > 0) {
        dict[@"matchedRuleId"] = [@(self.matchedRuleId) stringValue];
    }

    if ([self.matchedRuleType length] > 0) {
        dict[@"matchedRuleType"] = self.matchedRuleType;
        if (self.isDelayClosed) {
            dict[TSPKMonitorSceneKey] = TSPKPairDelayClose;
        } else {
            dict[TSPKMonitorSceneKey] = self.matchedRuleType;
        }
    }

    if ([self.matchedRuleName length] > 0) {
        dict[@"matchedRuleName"] = self.matchedRuleName;
    }

    if ([self.topPageName length] > 0) {
        dict[@"topPageName"] = self.topPageName;
    }
    
    if ([self.appStatus length] > 0) {
        dict[@"appStatus"] = self.appStatus;
    }
    
    if (self.apiModel.errorCode != nil) {
        dict[@"apiErrorCode"] = self.apiModel.errorCode;
    }
    
    NSString *settingVersion = [TSPKUtils settingVersion];
    if ([settingVersion length] > 0) {
        dict[@"settingVersion"] = settingVersion;
    }
    
    if (self.detectTime > 0) {
        dict[@"detectTime"] = @(self.detectTime);
    }
    
    dict[@"action"] = @(self.ruleEngineAction);
    
    if (self.totalDetectTime > 0) {
        dict[@"totalDetectTime"] = @(self.totalDetectTime);
    }
    
    if (self.ruleEngineResult.length > 0) {
        dict[@"reason"] = self.ruleEngineResult;
    }
    
    if (self.customAnchorCaseId.length > 0) {
        dict[@"customAnchorCaseId"] = self.customAnchorCaseId;
        if (self.isDelayClosed) {
            dict[TSPKMonitorSceneKey] = [NSString stringWithFormat:@"%@-%@", TSPKCustomAnchor, TSPKPairDelayClose];
        } else {
            dict[TSPKMonitorSceneKey] = TSPKCustomAnchor;
        }
    }
    
    if (self.customAnchorStartTopPage.length > 0) {
        dict[@"customAnchorStartTopPage"] = self.customAnchorStartTopPage;
    }
    
    if (self.customAnchorStopTopPage.length > 0) {
        dict[@"customAnchorStopTopPage"] = self.customAnchorStopTopPage;
    }

    return [NSDictionary dictionaryWithDictionary:dict];
}

- (NSDictionary *_Nonnull)formatDictionaryForAPIStatistics {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    if ([self.apiModel.apiClass isKindOfClass:[NSString class]] && [self.apiModel.apiClass length] > 0) {
        result[@"class_name"] = self.apiModel.apiClass;
    }
    
    if ([self.apiModel.apiMethod length] > 0) {
        result[@"method_name"] = self.apiModel.apiMethod;
    }
    
    if ([self.apiModel.pipelineType length] > 0) {
        result[@"api_type"] = self.apiModel.pipelineType;
    }
    
    if ([self.topPageName length] > 0) {
        result[@"top_page"] = self.topPageName;
    }
    
    result[@"invoke_time"] = @(self.unixTimestamp);
    return result.copy;
}

- (BOOL)isCustomAnchorCheck {
    return self.customAnchorCaseId.length > 0;
}

- (void)addReleaseContextInfoWithEventData:(TSPKEventData *)eventData {
    self.customAnchorCaseId = eventData.customAnchorCaseId;
    self.customAnchorStartDesc = eventData.customAnchorStartDesc;
    self.customAnchorStopDesc = eventData.customAnchorStopDesc;
    self.customAnchorStartTopPage = eventData.customAnchorStartTopPage;
    self.customAnchorStopTopPage = eventData.customAnchorStopTopPage;
}

- (void)addReleaseContextInfoToDic:(NSMutableDictionary *)mutableDic {
    if (self.isCustomAnchorCheck) {
        mutableDic[@"customAnchorCaseId"] = self.customAnchorCaseId;
    }
}

@end
