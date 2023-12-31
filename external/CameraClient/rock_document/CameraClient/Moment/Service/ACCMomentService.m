//
//  ACCMomentService.m
//  Pods
//
//  Created by Pinka on 2020/5/21.
//

#import "ACCMomentService.h"
//#import "ACCMomentMediaScanManager.h"
#import "ACCMomentATIMManager.h"
#import "ACCMomentDatabaseUpgradeManager.h"

#import <EffectPlatformSDK/EffectPlatform.h>
//#import <EffectPlatformSDK/EffectPlatform+AlgorithmModel.h>
#import <EffectSDK_iOS/RequirementDefine.h>

static NSString* ACCMomentServiceDidPublishPath(void)
{
    return [ACCMomentATIMManagerPath() stringByAppendingPathComponent:@"publishDict.plist"];
}

static NSString* ACCMomentServiceLastAIMPath(void)
{
    return [ACCMomentATIMManagerPath() stringByAppendingPathComponent:@"lastAIM.plist"];
}

static NSInteger const ACCMomentServiceJudgeUpdateCount = 3;

@interface ACCMomentService ()

@property (nonatomic, assign) BOOL isWaitingUpdateConfig;

@property (nonatomic, assign) BOOL isForeground;

@property (nonatomic, assign, readonly) BOOL bimModelRequire;

@property (nonatomic, assign) NSUInteger bimPerCallbackCount;

@property (nonatomic, copy  ) ACCMomentServiceCompletion bimCompletion;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *didPublishMomentIdDict;

@property (nonatomic, strong) NSMutableDictionary<NSString *, VEAIMomentTemplatePair *> *usedTemplates;

@end

@implementation ACCMomentService

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static ACCMomentService *service;
    dispatch_once(&onceToken, ^{
        service = [[ACCMomentService alloc] init];
    });
    
    return service;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _didPublishMomentIdDict = [NSKeyedUnarchiver unarchiveObjectWithFile:ACCMomentServiceDidPublishPath()];
        _usedTemplates = [[NSMutableDictionary alloc] init];
        
        if (!_didPublishMomentIdDict) {
            _didPublishMomentIdDict = [[NSMutableDictionary alloc] init];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(memoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [ACCMomentMediaScanManager shareInstance].multiThreadOptimize = NO;
    }
    
    return self;
}

- (void)memoryWarning:(NSNotification *)noti
{
    if ([ACCMomentMediaScanManager shareInstance].state == ACCMomentMediaScanManagerScanState_BackgroundScanning) {
        [[ACCMomentMediaScanManager shareInstance] stopScan];
    }
}

- (void)setCrops:(NSArray<NSNumber *> *)crops
{
    _crops = [crops copy];
    [ACCMomentMediaScanManager shareInstance].crops = crops;
}

- (void)setAssetFilter:(ACCMomentServiceMaterialFilter)assetFilter
{
    _assetFilter = assetFilter;
    [ACCMomentMediaScanManager shareInstance].assetFilter = assetFilter;
}

- (BOOL)bimModelRequire
{
    return [EffectPlatform isRequirementsDownloaded:@[@REQUIREMENT_MOMENT_TAG]];
}

- (BOOL)isAlready
{
    return self.bimModelRequire && [ACCMomentATIMManager shareInstance].aimIsReady && [ACCMomentATIMManager shareInstance].timIsReady;
}

- (BOOL)multiThreadOptimize
{
    return [ACCMomentMediaScanManager shareInstance].multiThreadOptimize;
}

- (void)setMultiThreadOptimize:(BOOL)multiThreadOptimize
{
    [ACCMomentMediaScanManager shareInstance].multiThreadOptimize = multiThreadOptimize;
}

- (NSInteger)scanQueueOperationCount
{
    return [ACCMomentMediaScanManager shareInstance].scanQueueOperationCount;
}

- (void)setScanQueueOperationCount:(NSInteger)scanQueueOperationCount
{
    [ACCMomentMediaScanManager shareInstance].scanQueueOperationCount = scanQueueOperationCount;
}

- (void)updateModelIfNotReady
{
    if (!self.bimModelRequire) {
        [self updateBIMModel];
    }
    
    if (![ACCMomentATIMManager shareInstance].aimIsReady) {
        [[ACCMomentATIMManager shareInstance] updateAIMConfig];
    }
}

- (void)updateConfigModel
{
    [self updateBIMModel];
    
    [[ACCMomentATIMManager shareInstance] updateAIMConfig];
    [[ACCMomentATIMManager shareInstance] updateTIMModel];
}

- (void)updateBIMModel
{
    [EffectPlatform downloadRequirements:@[@REQUIREMENT_MOMENT_TAG]
                              completion:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            if (self.bimCompletion) {
                if (self.isForeground) {
                    [self startForegroundMediaScanWithPerCallbackCount:self.bimPerCallbackCount
                                                            completion:self.bimCompletion];
                } else {
                    [self startBackgroundMediaScanWithCompletion:self.bimCompletion];
                }
                
                self.bimCompletion = nil;
            }
        }
    }];
}

- (void)cleanScanResultNotExistWithCompletion:(ACCMomentServiceCompletion)completion
{
    [[ACCMomentMediaScanManager shareInstance]
     processResultCleanWithCompletion:^(ACCMomentMediaScanManagerCompleteState state, ACCMomentMediaAsset *lastAsset, NSError * _Nullable error) {
        if (completion) {
            completion(state, lastAsset, error);
        }
    }];
}

- (void)startForegroundMediaScanWithPerCallbackCount:(NSUInteger)perCallbackCount
                                    completion:(ACCMomentServiceCompletion)completion
{
    self.isForeground = YES;
    if (!self.bimModelRequire) {
        self.bimPerCallbackCount = perCallbackCount;
        [self replaceCompletion:completion];
        return;
    }
    
    [[ACCMomentMediaScanManager shareInstance]
     startForegroundScanWithPerCallbackCount:perCallbackCount
     needAllScan:YES
     completion:^(ACCMomentMediaScanManagerCompleteState state, ACCMomentMediaAsset *lastAsset, NSError * _Nullable error) {
        if (completion) {
            completion(state, lastAsset, error);
        }
    }];
}

- (void)startBackgroundMediaScanWithCompletion:(ACCMomentServiceCompletion)completion
{
    [self startBackgroundMediaScanWithForce:NO completion:completion];
}

- (void)startBackgroundMediaScanWithForce:(BOOL)force
                               completion:(ACCMomentServiceCompletion _Nullable)completion
{
    BOOL foregroundflag = self.isForeground;
    if (!self.bimModelRequire) {
        if (foregroundflag) {
            if (force) {
                [self replaceCompletion:completion];
                self.isForeground = NO;
            } else {
                if (completion) {
                    completion(ACCMomentMediaScanManagerCompleteState_BeReplaced, nil, nil);
                }
            }
        } else {
            [self replaceCompletion:completion];
        }
        
        return;
    }
    
    if ([ACCMomentMediaScanManager shareInstance].state == ACCMomentMediaScanManagerScanState_ForegroundScanning ||
        [ACCMomentMediaScanManager shareInstance].state == ACCMomentMediaScanManagerScanState_ForegroundScanPaused) {
        if (!force) {
            if (completion) {
                completion(ACCMomentMediaScanManagerCompleteState_BeReplaced, nil, nil);
            }
            
            return;
        }
    }
    
    [[ACCMomentMediaScanManager shareInstance]
     startBackgroundScanWithCompletion:^(ACCMomentMediaScanManagerCompleteState state, ACCMomentMediaAsset *lastAsset, NSError * _Nullable error) {
         if (completion) {
             completion(state, lastAsset, error);
         }
    }];
}

- (void)replaceCompletion:(ACCMomentServiceCompletion)completion
{
    if (self.bimCompletion != completion) {
        if (self.bimCompletion) {
            self.bimCompletion(ACCMomentMediaScanManagerCompleteState_BeReplaced, nil, nil);
        }
        self.bimCompletion = completion;
    }
}

- (void)stopMediaScan
{
    self.isWaitingUpdateConfig = NO;
    
    [[ACCMomentMediaScanManager shareInstance] stopScan];
}


- (void)requestMomentsWithUpdateFlag:(BOOL)updateFlag
                      verifyTemplate:(ACCMomentServiceTemplateVerifyRequest)verifyTemplate
                            callback:(ACCMomentServiceMomentResult)callback
{
    ACCMomentATIMManagerAIMCompletion completion = ^(NSArray<ACCMomentAIMomentModel *> * _Nullable result, NSError * _Nullable error) {
        NSMutableArray *checkArr = [[NSMutableArray alloc] init];
        [result enumerateObjectsUsingBlock:^(ACCMomentAIMomentModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.templateId > 0) {
                ACCMVTemplateMergedInfo *info = [[ACCMVTemplateMergedInfo alloc] init];
                info.templateID = (NSUInteger)obj.templateId;
//                if (obj.templateType == ACCMomentTemplateType_CutSame) {
                    info.type = ACCMVTemplateTypeCutSame;
//                } else {
//                    info.type = ACCMVTemplateTypeClassic;
//                }
                [checkArr addObject:info];
            }
         }];
         
         // Last AIM Result
         NSArray *lastResult = [NSKeyedUnarchiver unarchiveObjectWithFile:ACCMomentServiceLastAIMPath()];
         NSMutableDictionary *lastResultDict = [[NSMutableDictionary alloc] init];
         [lastResult enumerateObjectsUsingBlock:^(ACCMomentAIMomentModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
             if (obj.identity) {
                 lastResultDict[obj.identity] = obj;
             }
         }];
        
        if (verifyTemplate && checkArr.count) {
             verifyTemplate(checkArr, ^(NSArray<ACCMVTemplateMergedInfo *> *templateList) {
                 NSMutableArray *newResult = [[NSMutableArray alloc] init];
                 NSMutableDictionary *checkDict = [[NSMutableDictionary alloc] init];
                 [templateList enumerateObjectsUsingBlock:^(ACCMVTemplateMergedInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                     NSString *theKey = [@(obj.templateID).stringValue stringByAppendingString:(obj.type == ACCMVTemplateTypeCutSame? @"Cutsame": @"Classic")];
                     checkDict[theKey] = @YES;
                 }];
                 
                 [result enumerateObjectsUsingBlock:^(ACCMomentAIMomentModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                     if (obj.templateId > 0) {
                         NSString *theKey = [@(obj.templateId).stringValue stringByAppendingString:@"Cutsame"];
                         if (checkDict[theKey]) {
                             [newResult addObject:obj];
                         }
                     } else {
                         [newResult addObject:obj];
                     }
                 }];
                 
                 NSMutableArray *orderResult = [[NSMutableArray alloc] initWithArray:newResult];
                 [newResult enumerateObjectsUsingBlock:^(ACCMomentAIMomentModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                     
                     ACCMomentAIMomentModel *theLastMoment = lastResultDict[obj.identity];
                     if (theLastMoment) {
                         NSInteger __block changeCount = 0;
                         [obj.uids enumerateObjectsUsingBlock:^(NSNumber * _Nonnull oneUid, NSUInteger idx, BOOL * _Nonnull stop) {
                             if (![theLastMoment.uids containsObject:oneUid]) {
                                 changeCount += 1;
                                 
                                 if (changeCount >= ACCMomentServiceJudgeUpdateCount) {
                                     *stop = YES;
                                 }
                             }
                         }];
                         
                         obj.isUpdate = (changeCount >= ACCMomentServiceJudgeUpdateCount);
                     } else {
                         obj.isNew = YES;
                     }
                 }];
                 
                 if (updateFlag) {
                     [NSKeyedArchiver archiveRootObject:orderResult toFile:ACCMomentServiceLastAIMPath()];
                 }
                 
                 if (callback) {
                     callback(orderResult, error);
                 }
             });
         } else {
             NSMutableArray *orderResult = [[NSMutableArray alloc] initWithArray:result];
             [result enumerateObjectsUsingBlock:^(ACCMomentAIMomentModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

                 ACCMomentAIMomentModel *theLastMoment = lastResultDict[obj.identity];
                 if (theLastMoment) {
                     NSInteger __block changeCount = 0;
                     [obj.uids enumerateObjectsUsingBlock:^(NSNumber * _Nonnull oneUid, NSUInteger idx, BOOL * _Nonnull stop) {
                         if (![theLastMoment.uids containsObject:oneUid]) {
                             changeCount += 1;
                             
                             if (changeCount >= ACCMomentServiceJudgeUpdateCount) {
                                 *stop = YES;
                             }
                         }
                     }];
                     
                     obj.isUpdate = (changeCount >= ACCMomentServiceJudgeUpdateCount);
                 } else {
                     obj.isNew = YES;
                 }
             }];
             
             if (updateFlag) {
                 [NSKeyedArchiver archiveRootObject:orderResult toFile:ACCMomentServiceLastAIMPath()];
             }
             
             if (callback) {
                 callback(orderResult, error);
             }
         }
    };
    
    if ([[ACCMomentDatabaseUpgradeManager shareInstance] checkDatabaseUpgradeState] != ACCMomentDatabaseUpgradeState_NoNeed) {
        // Last AIM Result
        NSArray *result = [NSKeyedUnarchiver unarchiveObjectWithFile:ACCMomentServiceLastAIMPath()];
        if (result) {
            NSMutableArray *realResult = [NSMutableArray arrayWithArray:result];
            
            [result enumerateObjectsUsingBlock:^(ACCMomentAIMomentModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                PHFetchResult<PHAsset *> *test = [PHAsset fetchAssetsWithLocalIdentifiers:obj.materialIds options:nil];
                if (test.count != obj.materialIds.count) {
                    [realResult removeObject:obj];
                }
            }];
            
            completion(realResult, nil);
        } else {
            completion(@[], nil);
        }
    } else {
        [[ACCMomentATIMManager shareInstance] requestAIMResult:completion];
    }
}

- (void)requestTemplateWithMoment:(ACCMomentAIMomentModel *)moment
                   verifyTemplate:(ACCMomentServiceTemplateVerifyRequest)verifyTemplate
                         callback:(ACCMomentServiceTemplateResult)callback
{
    if (!callback) {
        return;
    }
    
    [[ACCMomentATIMManager shareInstance]
     requestTIMResultWithAIMoment:moment
     usedPairs:self.usedTemplates.allValues
     completion:^(NSArray<ACCMomentTemplateModel *> * _Nonnull result, NSError * _Nonnull error) {
        NSMutableArray *checkArr = [[NSMutableArray alloc] init];
        [result enumerateObjectsUsingBlock:^(ACCMomentTemplateModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ACCMVTemplateMergedInfo *info = [[ACCMVTemplateMergedInfo alloc] init];
            info.templateID = obj.templateId;
            if (obj.templateType == ACCMomentTemplateType_CutSame) {
                info.type = ACCMVTemplateTypeCutSame;
            } else {
                info.type = ACCMVTemplateTypeClassic;
            }
            
            [checkArr addObject:info];
        }];

        ACCMomentTemplateModel *__block usedTemplate = nil;
        if (verifyTemplate) {
            verifyTemplate(checkArr, ^(NSArray<ACCMVTemplateMergedInfo *> *templateList) {
                NSMutableArray *newResult = [[NSMutableArray alloc] init];
                NSMutableDictionary *checkDict = [[NSMutableDictionary alloc] init];
                [templateList enumerateObjectsUsingBlock:^(ACCMVTemplateMergedInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *theKey = [@(obj.templateID).stringValue stringByAppendingString:(obj.type == ACCMVTemplateTypeCutSame? @"Cutsame": @"Classic")];
                    checkDict[theKey] = @YES;
                }];
                
                [result enumerateObjectsUsingBlock:^(ACCMomentTemplateModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *theKey = [@(obj.templateId).stringValue stringByAppendingString:(obj.templateType == ACCMomentTemplateType_CutSame? @"Cutsame": @"Classic")];
                    if (checkDict[theKey]) {
                        [newResult addObject:obj];
                    }
                }];
                
                usedTemplate = newResult.firstObject;
                if (callback) {
                    callback(newResult, error);
                }
                
                if (usedTemplate && moment.identity.length) {
                    VEAIMomentTemplatePair *pair = [[VEAIMomentTemplatePair alloc] init];
                    pair.templateId = usedTemplate.templateId;
                    pair.momentId = moment.identity;
                    pair.momentSource = moment.momentSource;
                    self.usedTemplates[moment.identity] = pair;
                }
            });
        } else {
            usedTemplate = result.firstObject;
            if (callback) {
                callback(result, error);
            }
            
            if (usedTemplate && moment.identity.length) {
                VEAIMomentTemplatePair *pair = [[VEAIMomentTemplatePair alloc] init];
                pair.templateId = usedTemplate.templateId;
                pair.momentId = moment.identity;
                pair.momentSource = moment.momentSource;
                self.usedTemplates[moment.identity] = pair;
            }
        }
    }];
}

- (void)markMomentAlreadyPublish:(NSString *)momentId
{
    if (!momentId) {
        return;
    }
    
    self.didPublishMomentIdDict[momentId] = @YES;
    [NSKeyedArchiver archiveRootObject:self.didPublishMomentIdDict toFile:ACCMomentServiceDidPublishPath()];
}

- (void)clearAllData
{
    [[ACCMomentMediaScanManager shareInstance] clearDatas];
}

- (NSArray<NSString *> *)urlPrefix
{
    return [[ACCMomentATIMManager shareInstance] urlPrefix];
}

- (void)setAimPannelName:(NSString *)aimPannelName
{
    [ACCMomentATIMManager shareInstance].pannelName = aimPannelName;
}

- (NSString *)aimPannelName
{
    return [ACCMomentATIMManager shareInstance].pannelName;
}

- (void)setScanLimitCount:(NSUInteger)scanLimitCount
{
    [ACCMomentMediaScanManager shareInstance].scanLimitCount = scanLimitCount;
    [ACCMomentATIMManager shareInstance].scanLimitCount = scanLimitCount;
}

- (NSUInteger)scanLimitCount
{
    return [ACCMomentMediaScanManager shareInstance].scanLimitCount;
}

- (void)setScanRedundancyScale:(CGFloat)scanRedundancyScale
{
    [ACCMomentMediaScanManager shareInstance].scanRedundancyScale = scanRedundancyScale;
}

- (CGFloat)scanRedundancyScale
{
    return [ACCMomentMediaScanManager shareInstance].scanRedundancyScale  ;
}

@end
