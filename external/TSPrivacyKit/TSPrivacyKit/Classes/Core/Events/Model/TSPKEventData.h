//
//  TSPKEventData.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/19.
//

#import <Foundation/Foundation.h>

#import "TSPKAPIModel.h"
#import "TSPKStoreFactory.h"

@class TSPKFuseModel;
@class TSPKRuleExecuteResultModel;

@interface TSPKEventData : NSObject <NSCopying>

//API related
@property (nonatomic, strong, nullable) TSPKAPIModel *apiModel;

@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) NSTimeInterval unixTimestamp;
@property (nonatomic) NSTimeInterval serverTimestamp;
@property (nonatomic) NSTimeInterval lastEnterBackgroundTimestamp;

// result
@property (nonatomic) NSInteger handleResultAction;

//downgrade related
@property (nonatomic, strong, nullable) TSPKFuseModel * fuseModel;

//badcase related
@property (nonatomic) NSInteger matchedRuleId;
@property (nonatomic, copy, nullable) NSString * matchedRuleName;
@property (nonatomic, copy, nullable) NSString * matchedRuleType;
@property (nonatomic) BOOL isGrayScaleRule;
@property (nonatomic, copy, nullable) NSDictionary *matchedRuleParams;
@property (nonatomic, copy, nullable) NSString *unreleaseAddress;

//rule engine result
@property (nonatomic, copy, nullable) NSString *ruleEngineResult;
@property (nonatomic, assign) NSInteger ruleEngineAction;
@property (nonatomic, assign) BOOL cacheNeedUpdate;

//info
@property (nonatomic) NSTimeInterval timeGapToDetect;
@property (nonatomic) NSTimeInterval timeDelay;
@property (nonatomic, assign) NSInteger detectTime;
@property (nonatomic, assign) NSInteger totalDetectTime;
@property (nonatomic, nullable) NSString * extraInfo;
/// NvWa use it to extract info
@property (nonatomic, nullable) NSDictionary * extraInfoDic;
/// only store unreleased event
@property (nonatomic, strong, nullable) NSMutableArray<TSPKEventData *> * subEvents;
@property (nonatomic, strong, nullable) NSMutableArray<NSString *> * warningTypes;

//store info
@property (nonatomic, copy, nullable) NSString * storeIdentifier;
@property (nonatomic) TSPKStoreType storeType;

//app context
@property (nonatomic, copy, nullable) NSString *appStatus;
@property (nonatomic, copy, nullable) NSString *topPageName;
@property (nonatomic) NSTimeInterval timeLastDidEnterBackground;
@property (nonatomic) NSTimeInterval timeLastWillEnterForeground;

// camera&audio
@property (nonatomic, assign) BOOL isReleased;
@property (nonatomic, assign) BOOL isDelayClosed;

@property (nonatomic, strong, nullable) NSMutableArray<TSPKRuleExecuteResultModel *> *ruleExecuteResults;

//bpea context
@property (nonatomic, copy, nullable) NSDictionary *bpeaContext;
@property (nonatomic, copy, nullable) NSString *uuid;


@property (nonatomic, copy, nullable) NSString *customAnchorCaseId;
@property (nonatomic, copy, nullable) NSString *customAnchorStartDesc;
@property (nonatomic, copy, nullable) NSString *customAnchorStopDesc;
@property (nonatomic, copy, nullable) NSString *customAnchorStartTopPage;
@property (nonatomic, copy, nullable) NSString *customAnchorStopTopPage;
- (BOOL)isCustomAnchorCheck;

- (NSDictionary *_Nonnull)formatDictionaryForAPIStatistics;
- (NSDictionary *_Nonnull)formatDictionary;
- (NSDictionary *_Nonnull)formatFilterDictionary;

- (void)addReleaseContextInfoWithEventData:(nonnull TSPKEventData *)eventData;

- (void)addReleaseContextInfoToDic:(nonnull NSMutableDictionary *)mutableDic;

@end



