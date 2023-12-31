//
//  ACCMomentMediaScanManager.m
//  Pods
//
//  Created by Pinka on 2020/5/14.
//

#import "ACCMomentMediaScanManager.h"
#import "ACCMediaSourceManager.h"
#import "ACCMomentPhotoCalculateOperation.h"
#import "ACCMomentCIMManager.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCMomentDatabaseUpgradeManager.h"

NSInteger const ACCMomentMediaScanDefaultOperationCount = 50;
static NSInteger const ACCMomentMediaScanManagerMaxQueueCount = 2;
static NSInteger const ACCMomentMediaScanManagerBackgroundPerCount = 100;

@interface ACCMomentMediaScanManager ()

#pragma mark - Public
@property (nonatomic, assign, readwrite) ACCMomentMediaScanManagerScanState state;

#pragma mark - Private
// Scan
@property (nonatomic, strong) VEAIMomentAlgorithm *aiAlgorithm;

@property (nonatomic, strong) ACCMomentMediaScanManagerCompletion completion;

@property (atomic, assign) BOOL needAllScan;

@property (atomic, assign) NSUInteger curValidScanCount;

@property (atomic, assign) NSUInteger perValidScanCount;

@property (nonatomic, strong) PHFetchResult<PHAsset *> *curResult;

@property (nonatomic, assign) NSUInteger curScanDate;

@property (nonatomic, strong) ACCMediaSourceManager *sourceManager;

@property (nonatomic, strong, readwrite) ACCMomentMediaDataProvider *dataProvider;

@property (nonatomic, strong) NSOperationQueue *imgBIMQueue;

@property (nonatomic, strong) NSOperationQueue *videoBIMQueue;

@property (atomic, assign) NSInteger curScanPageIdx;

@property (nonatomic, strong) dispatch_queue_t completeOpQueue;

@property (nonatomic, copy  ) NSArray<dispatch_queue_t> *imageQueues;

@property (nonatomic, strong) dispatch_queue_t commonQueue;

@property (atomic, assign) NSUInteger targetUpgradeCount;

// GEO
@property (nonatomic, strong) NSOperationQueue *geoQueue;

// CIM
@property (nonatomic, strong) ACCMomentCIMManager *cimManager;

@property (nonatomic, strong) ACCMomentMediaAsset *lastAsset;

@end

@implementation ACCMomentMediaScanManager

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterAppBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterAppForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wiilTerminate:) name:UIApplicationWillTerminateNotification object:nil];
        
        _targetUpgradeCount = -1;
        _sourceManager = [[ACCMediaSourceManager alloc] init];
        
        if ([[ACCMomentDatabaseUpgradeManager shareInstance] checkDatabaseUpgradeState] == ACCMomentDatabaseUpgradeState_IsUpgrading) {
            _dataProvider = [ACCMomentMediaDataProvider upgradeProvider];
        } else {
            _dataProvider = [ACCMomentMediaDataProvider normalProvider];
        }
        
        _scanQueueOperationCount = ACCMomentMediaScanDefaultOperationCount;
       
        {
            _multiThreadOptimize = YES;
            
            _imgBIMQueue = [[NSOperationQueue alloc] init];
            _imgBIMQueue.maxConcurrentOperationCount = ACCMomentMediaScanManagerMaxQueueCount;
            
            _videoBIMQueue = [[NSOperationQueue alloc] init];
            _videoBIMQueue.maxConcurrentOperationCount = 1;
        }
        
        _geoQueue = [[NSOperationQueue alloc] init];
        _geoQueue.maxConcurrentOperationCount = 1;
        
        _cimManager = [[ACCMomentCIMManager alloc] initWithDataProvider:_dataProvider];
        
        _completeOpQueue = dispatch_queue_create("com.acc.media.scan.manager.complete", DISPATCH_QUEUE_SERIAL);
        
        _scanRedundancyScale = 0.2;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didUpgraded:)
                                                     name:kACCMomentDatabaseDidUpgradedNotification
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Notification
- (void)enterAppBackground:(NSNotification *)notification
{
    [self pauseScan];
}

- (void)enterAppForeground:(NSNotification *)notification
{
    [self resumeScan];
}

- (void)wiilTerminate:(NSNotification *)notification
{
    [self stopScan];
}

- (void)didUpgraded:(NSNotification *)noti
{
    self.targetUpgradeCount = -1;
}

#pragma mark - Public API
+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static ACCMomentMediaScanManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[ACCMomentMediaScanManager alloc] init];
    });
    
    return manager;
}

- (void)startForegroundScanWithPerCallbackCount:(NSUInteger)perCallbackCount
                                    needAllScan:(BOOL)needAllScan
                                     completion:(ACCMomentMediaScanManagerCompletion)completion
{
    if (self.state == ACCMomentMediaScanManagerScanState_BackgroundScanning ||
        self.state == ACCMomentMediaScanManagerScanState_BackgroundScanPaused) {
        [self stopScan];
    }
    
    dispatch_block_t block = ^{
        self.perValidScanCount = perCallbackCount;
        self.needAllScan = needAllScan;
        [self replaceCompletion:completion];
        
        if (self.isScanning) {
            self.state = ACCMomentMediaScanManagerScanState_ForegroundScanning;
        } else if (self.state == ACCMomentMediaScanManagerScanState_Idle) {
            @weakify(self);
            self.state = ACCMomentMediaScanManagerScanState_ForegroundScanning;
            
            [self.sourceManager
             assetWithType:ACCMediaSourceType_Image|ACCMediaSourceType_Video
             ascending:NO
             configFetchOptions:^(PHFetchOptions * _Nonnull fetchOptions) {
                ;
            }
             completion:^(PHFetchResult<PHAsset *> * _Nonnull result) {
                @strongify(self);
                if (result) {
                    self.curResult = result;
                    [self processScanResult];
                } else {
                    if (self.completion) {
                        self.completion(ACCMomentMediaScanManagerCompleteState_Fail, nil, nil);
                    }
                    
                    self.state = ACCMomentMediaScanManagerScanState_Idle;
                }
            }];
        } else {
            self.state = ACCMomentMediaScanManagerScanState_ForegroundScanning;
            [self resumeScan];
        }
    };
    
    if ([[ACCMomentDatabaseUpgradeManager shareInstance] checkDatabaseUpgradeState] == ACCMomentDatabaseUpgradeState_NeedUpgrade) {
        [[ACCMomentDatabaseUpgradeManager shareInstance] startDatabaseUpgrade];
        
        [[ACCMomentMediaDataProvider normalProvider] allBIMCount:^(NSUInteger bimCount) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.targetUpgradeCount = bimCount;
                self.dataProvider = [ACCMomentMediaDataProvider upgradeProvider];
                self.cimManager = [[ACCMomentCIMManager alloc] initWithDataProvider:self.dataProvider];
                block();
            });
        }];
    } else {
        block();
    }
}

- (void)startBackgroundScanWithCompletion:(ACCMomentMediaScanManagerCompletion)completion
{
    if (self.state == ACCMomentMediaScanManagerScanState_ForegroundScanning ||
        self.state == ACCMomentMediaScanManagerScanState_ForegroundScanPaused) {
        [self stopScan];
    }
    
    dispatch_block_t block = ^{
        self.needAllScan = YES;
        self.perValidScanCount = ACCMomentMediaScanManagerBackgroundPerCount;
        [self replaceCompletion:completion];
        
        if (self.state == ACCMomentMediaScanManagerScanState_Idle) {
            self.state = ACCMomentMediaScanManagerScanState_BackgroundScanning;
            
            @weakify(self);
            [self.sourceManager
             assetWithType:ACCMediaSourceType_Image|ACCMediaSourceType_Video
             ascending:NO
             configFetchOptions:^(PHFetchOptions * _Nonnull fetchOptions) {
                ;
            }
             completion:^(PHFetchResult<PHAsset *> * _Nonnull result) {
                @strongify(self);
                if (result) {
                    self.curResult = result;
                    [self processScanResult];
                } else {
                    if (self.completion) {
                        self.completion(ACCMomentMediaScanManagerCompleteState_Fail, nil, nil);
                    }
                    
                    self.state = ACCMomentMediaScanManagerScanState_Idle;
                }
            }];
        } else {
            self.state = ACCMomentMediaScanManagerScanState_BackgroundScanning;
            [self resumeScan];
        }
    };
    
    if ([[ACCMomentDatabaseUpgradeManager shareInstance] checkDatabaseUpgradeState] == ACCMomentDatabaseUpgradeState_NeedUpgrade) {
        [[ACCMomentDatabaseUpgradeManager shareInstance] startDatabaseUpgrade];
        
        [[ACCMomentMediaDataProvider normalProvider] allBIMCount:^(NSUInteger bimCount) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.targetUpgradeCount = bimCount;
                self.dataProvider = [ACCMomentMediaDataProvider upgradeProvider];
                self.cimManager = [[ACCMomentCIMManager alloc] initWithDataProvider:self.dataProvider];
                block();
            });
        }];
    } else {
        block();
    }
}

- (void)stopScan
{
    [self.videoBIMQueue cancelAllOperations];
    [self.imgBIMQueue cancelAllOperations];
    
    if (self.completion) {
        self.completion(ACCMomentMediaScanManagerCompleteState_Canceled, nil, nil);
    }
    
    self.state = ACCMomentMediaScanManagerScanState_Idle;
}

- (void)pauseScan
{
    BOOL scaningFlag = self.isScanning;
    
    if (self.state == ACCMomentMediaScanManagerScanState_ForegroundScanning) {
        self.state = ACCMomentMediaScanManagerScanState_ForegroundScanPaused;
    } else if (self.state == ACCMomentMediaScanManagerScanState_BackgroundScanning) {
        self.state = ACCMomentMediaScanManagerScanState_BackgroundScanPaused;
    }
    
    if (scaningFlag) {
        [self.imgBIMQueue setSuspended:YES];
        [self.videoBIMQueue setSuspended:YES];
    }
}

- (void)resumeScan
{
    BOOL pauseFlag = self.isPaused;
    
    if (self.state == ACCMomentMediaScanManagerScanState_ForegroundScanPaused) {
        self.state = ACCMomentMediaScanManagerScanState_ForegroundScanning;
    } else if (self.state == ACCMomentMediaScanManagerScanState_BackgroundScanPaused) {
        self.state = ACCMomentMediaScanManagerScanState_BackgroundScanning;
    }
    
    if (pauseFlag) {
        [self.imgBIMQueue setSuspended:NO];
        [self.videoBIMQueue setSuspended:NO];
    }
}

- (void)processResultCleanWithCompletion:(ACCMomentMediaScanManagerCompletion)completion
{
    @weakify(self);
    [self.sourceManager
     assetWithType:ACCMediaSourceType_Image|ACCMediaSourceType_Video
     ascending:NO
     configFetchOptions:^(PHFetchOptions * _Nonnull fetchOptions) {
        ;
    }
     completion:^(PHFetchResult<PHAsset *> * _Nonnull result) {
        @strongify(self);
        if (result) {
            [self.dataProvider cleanBIMWhichNotExistInAssetResult:result
                                                         scanDate:[[NSDate date] timeIntervalSince1970]*1000
                                                       completion:^(NSError * _Nullable error) {
                if (completion) {
                    completion(error == nil? ACCMomentMediaScanManagerCompleteState_AllCompleted: ACCMomentMediaScanManagerCompleteState_Fail, nil,
                               error);
                }
            }];
        } else {
            if (completion) {
                completion(ACCMomentMediaScanManagerCompleteState_Fail, nil, nil);
            }
        }
    }];
    
    if (self.scanLimitCount > 0 && self.scanRedundancyScale > 0.0) {
        NSUInteger count = (1.0+self.scanRedundancyScale) * self.scanLimitCount;
        [self.dataProvider cleanRedundancyBIMCount:count
                                        completion:nil];
    }
}

- (BOOL)isScanning
{
    return (self.state == ACCMomentMediaScanManagerScanState_ForegroundScanning || self.state == ACCMomentMediaScanManagerScanState_BackgroundScanning);
}

- (BOOL)isPaused
{
    return (self.state == ACCMomentMediaScanManagerScanState_ForegroundScanPaused || self.state == ACCMomentMediaScanManagerScanState_BackgroundScanPaused);
}

- (void)setCrops:(NSArray<NSNumber *> *)crops
{
    _crops = [crops copy];
    [ACCMomentPhotoCalculateOperation setCrops:crops];
}

#pragma mark - Lazy load
- (VEAIMomentAlgorithm *)aiAlgorithm
{
    if (!_aiAlgorithm) {
        VEAlgorithmConfig *config = [VEAlgorithmConfig new];
        config.configPath = @"{}";
        config.tempRecPath = @"";
        config.superParams = 0b11111101111;
        config.resourceFinder = [IESMMParamModule getResourceFinder];
        config.initType = VEAlgorithmInitTypeMoment;
        config.serviceCount = ((self.multiThreadOptimize && self.state == ACCMomentMediaScanManagerScanState_ForegroundScanning)?
                               ACCMomentMediaScanManagerMaxQueueCount+1: 1);
        
        _aiAlgorithm = [[VEAIMomentAlgorithm alloc] initWithConfig:config];
        self.cimManager.aiAlgorithm = _aiAlgorithm;
    }
    
    return _aiAlgorithm;
}

- (NSArray<dispatch_queue_t> *)imageQueues
{
    if (!_imageQueues) {
        NSMutableArray *tmp = [[NSMutableArray alloc] init];
        
        for (NSInteger i = 0; i < ACCMomentMediaScanManagerMaxQueueCount; i++) {
            NSString *name = [@"com.acc.moment.calculate.image.op" stringByAppendingFormat:@"%ld", (long)i];
            dispatch_queue_t oneQueue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
            [tmp addObject:oneQueue];
        }
        
        _imageQueues = [tmp copy];
    }
    
    return _imageQueues;
}

- (dispatch_queue_t)commonQueue
{
    if (!_commonQueue) {
        _commonQueue = dispatch_queue_create("com.acc.moment.calculate.common.op", DISPATCH_QUEUE_SERIAL);
    }
    
    return _commonQueue;
}

#pragma mark - Private Methods
- (void)processScanResult
{
    @weakify(self);
    CFAbsoluteTime ctime = CFAbsoluteTimeGetCurrent();
    
    self.curScanDate = [[NSDate date] timeIntervalSince1970]*1000;
    [self.dataProvider
     updateAssetResult:self.curResult
     filter:^BOOL(PHAsset * _Nonnull asset) {
        @strongify(self);
        if (self.assetFilter) {
            return (self.assetFilter(asset));
        }
        
        return YES;
    }
     scanDate:self.curScanDate
     limitCount:self.scanLimitCount
     completion:^(NSError * _Nullable error) {
        @strongify(self);
        CFAbsoluteTime gap = CFAbsoluteTimeGetCurrent() - ctime;
        [ACCMonitor() trackService:@"moment_filter_duration"
                            status:1
                             extra:@{
                                 @"duration": @(gap)
                             }];
        
        if (error) {
            [self.videoBIMQueue cancelAllOperations];
            [self.imgBIMQueue cancelAllOperations];
            
            if (self.completion) {
                self.completion(ACCMomentMediaScanManagerCompleteState_Fail, nil, error);
            }
            
            self.state = ACCMomentMediaScanManagerScanState_Idle;
        } else {
            [self restartCalculatePhotosFromDatabase];
        }
    }];
}

- (void)restartCalculatePhotosFromDatabase
{
    [self.dataProvider cleanPrepareAssetsWithCompletion:nil];
    self.curScanPageIdx = 0;
    self.curValidScanCount = 0;
    self.lastAsset = nil;
    [self calculatePhotosFromDatabase];
}

- (void)replaceCompletion:(ACCMomentMediaScanManagerCompletion)completion
{
    if (self.completion != completion) {
        if (self.completion) {
            self.completion(ACCMomentMediaScanManagerCompleteState_BeReplaced, nil, nil);
        }
        self.completion = completion;
    }
}

- (void)calculatePhotosFromDatabase
{
    @weakify(self);
    [self.dataProvider loadPrepareAssetsWithLimit:self.scanQueueOperationCount
                                        pageIndex:self.curScanPageIdx
                                  videoLoadConfig:ACCMomentMediaDataProviderVideoCofig_Descending
                                      resultBlock:^(NSArray<ACCMomentMediaAsset *> * _Nullable result, NSUInteger allTotalCount, BOOL endFlag, NSError * _Nullable error) {
        @strongify(self);
        NSInteger totalCount = result.count;
        
        if (totalCount == 0) {
            if (self.completion) {
                self.completion(ACCMomentMediaScanManagerCompleteState_AllCompleted, self.lastAsset, error);
            }
            
            self.state = ACCMomentMediaScanManagerScanState_Idle;
            return;
        }
        
        NSInteger __block curCount = 0;
        NSMutableArray *partBIMResult = [[NSMutableArray alloc] init];
        
        ACCMomentMediaAsset __block *theLastAsset = result.lastObject;
        [result enumerateObjectsUsingBlock:^(ACCMomentMediaAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
            if (asset.creationDate.timeIntervalSince1970 < theLastAsset.creationDate.timeIntervalSince1970) {
                theLastAsset = asset;
            }
        }];
        self.lastAsset = theLastAsset;
        
        void (^completion)(void) = ^{
            @strongify(self);
            curCount += 1;
            
            if (curCount == totalCount) {
                [self.dataProvider updateBIMResult:partBIMResult completion:^(NSError * _Nullable error) {
                    
                }];

                NSUInteger lastValidScanCount = self.curValidScanCount;
                self.curValidScanCount += partBIMResult.count;
                NSUInteger lastIdx = 0, curIdx = 0;
                if (self.perValidScanCount > 0) {
                    lastIdx = lastValidScanCount/self.perValidScanCount;
                    curIdx = self.curValidScanCount/self.perValidScanCount;
                }

                if (endFlag) {
                    [self.dataProvider cleanPrepareAssetsWithCompletion:^(NSError * _Nullable error) {
                        ;
                    }];
                }
                
                if (endFlag ||
                    curIdx > lastIdx) {
                    [self.cimManager calculateCIMResult:^(VEAIMomentCIMResult * _Nonnull cimResult, NSError * _Nonnull error) {
                        if (error) {
                            AWELogToolError(AWELogToolTagMV, @"[calculateCIMResult] -- error:%@", error);
                        }
                        
                        if (self.completion) {
                            ACCMomentMediaScanManagerCompleteState completeState = ACCMomentMediaScanManagerCompleteState_AllCompleted;
                            if (!endFlag) {
                                completeState = ACCMomentMediaScanManagerCompleteState_HasMore;
                            }
                            
                            if (self.targetUpgradeCount >= 0) {
                                ACCMomentMediaScanManagerCompletion blockCompletion = self.completion;
                                [self.dataProvider allBIMCount:^(NSUInteger bimCount) {
                                    @strongify(self);
                                    if (bimCount >= self.targetUpgradeCount ||
                                        completeState == ACCMomentMediaScanManagerCompleteState_AllCompleted) {
                                        [[ACCMomentDatabaseUpgradeManager shareInstance] didCompletedDatabaseUpgrade];
                                    }
                                    
                                    blockCompletion(completeState, theLastAsset, nil);
                                }];
                            } else {
                                self.completion(completeState, theLastAsset, nil);
                            }
                            
                        }
                        
                        if (endFlag || !self.needAllScan) {
                            self.state = ACCMomentMediaScanManagerScanState_Idle;
                        }
                    }];
                    
                    if (!endFlag) {
                        if (self.perValidScanCount > 0) {
                            if (self.needAllScan) {
                                self.curScanPageIdx += 1;
                                [self calculatePhotosFromDatabase];
                            } else {
                                self.state = ACCMomentMediaScanManagerScanState_Idle;
                            }
                        } else {
                            self.state = ACCMomentMediaScanManagerScanState_Idle;
                        }
                    }
                } else {
                    self.curScanPageIdx += 1;
                    [self calculatePhotosFromDatabase];
                }
            }
        };
        
        NSInteger __block imageQueueCount = 0;
        BOOL useMultiThread = (self.multiThreadOptimize && self.state == ACCMomentMediaScanManagerScanState_ForegroundScanning);
        [result enumerateObjectsUsingBlock:^(ACCMomentMediaAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
            @strongify(self);
            ACCMomentPhotoCalculateOperation *op = [[ACCMomentPhotoCalculateOperation alloc] init];
            op.asset = asset;
            op.aiAlgorithm = self.aiAlgorithm;
            op.completionBlock = completion;
            
            if (useMultiThread) {
                if (PHAssetMediaTypeVideo == asset.mediaType) {
                    op.calculateQueue = self.commonQueue;
                    op.calculateIndex = ACCMomentMediaScanManagerMaxQueueCount;
                } else {
                    op.calculateQueue = self.imageQueues[imageQueueCount];
                    op.calculateIndex = imageQueueCount;
                    imageQueueCount += 1;
                    if (imageQueueCount == ACCMomentMediaScanManagerMaxQueueCount) {
                        imageQueueCount = 0;
                    }
                }
            } else {
                op.calculateQueue = self.commonQueue;
                op.calculateIndex = 0;
            }
            
            AWELogToolInfo(AWELogToolTagRecord, @"当前moment扫描聚合线程数%@", useMultiThread ? @(ACCMomentMediaScanManagerMaxQueueCount+1) : @(1));
            
            op.bimCompletion = ^(ACCMomentPhotoCalculateOperationResult * _Nullable result) {
                if (result.bimResult) {
                    NSMutableArray *arr = [[NSMutableArray alloc] init];
                    ACCMomentBIMResult *bim = [[ACCMomentBIMResult alloc] initWithVEBIM:result.bimResult];
                    bim.orientation = result.orientation;
                    bim.imageExif = result.imageExif;
                    bim.videoCreateDateString = result.videoCreateDateString;
                    bim.videoModelString = result.videoModelString;
                    [bim configWithAssetModel:asset];
                    if (bim) {
                        [arr addObject:bim];
                    }
                    
                    [partBIMResult addObjectsFromArray:arr];
                }
            };
            
            if (PHAssetMediaTypeImage == asset.mediaType) {
                [self.imgBIMQueue addOperation:op];
            } else {
                [self.videoBIMQueue addOperation:op];
            }
        }];
    }];
}

- (void)destroyAIAlgorithm
{
    _aiAlgorithm = nil;
}

- (void)releaseQueues
{
    _imageQueues = nil;
    _commonQueue = nil;
}

- (void)clearDatas
{
    [self.dataProvider cleanAllTable];
}

- (void)setSuperParams:(int64_t)superParams
{
    VEAlgorithmConfig *config = [VEAlgorithmConfig new];
    config.configPath = @"{}";
    config.tempRecPath = @"";
    config.superParams = superParams;
    config.resourceFinder = [IESMMParamModule getResourceFinder];
    config.initType = VEAlgorithmInitTypeMoment;
    config.serviceCount = ACCMomentMediaScanManagerMaxQueueCount+1;
    
    _aiAlgorithm = [[VEAIMomentAlgorithm alloc] initWithConfig:config];
    self.cimManager.aiAlgorithm = _aiAlgorithm;
}

- (void)setState:(ACCMomentMediaScanManagerScanState)state
{
    ACCMomentMediaScanManagerScanState lastState = _state;
    
    _state = state;
    
    if (ACCMomentMediaScanManagerScanState_Idle == state) {
        _completion = nil;
        [self destroyAIAlgorithm];
        [self releaseQueues];
    } else if (ACCMomentMediaScanManagerScanState_ForegroundScanning == state &&
               ACCMomentMediaScanManagerScanState_ForegroundScanPaused != lastState) {
        if (self.multiThreadOptimize) {
            _imgBIMQueue = [[NSOperationQueue alloc] init];
            _imgBIMQueue.maxConcurrentOperationCount = ACCMomentMediaScanManagerMaxQueueCount;
            
            _videoBIMQueue = [[NSOperationQueue alloc] init];
            _videoBIMQueue.maxConcurrentOperationCount = 1;
        } else {
            _imgBIMQueue = [[NSOperationQueue alloc] init];
            _imgBIMQueue.maxConcurrentOperationCount = 1;
            _videoBIMQueue = _imgBIMQueue;
        }
    } else if (ACCMomentMediaScanManagerScanState_BackgroundScanning == state &&
               ACCMomentMediaScanManagerScanState_BackgroundScanPaused != lastState) {
        _imgBIMQueue = [[NSOperationQueue alloc] init];
        _imgBIMQueue.maxConcurrentOperationCount = 1;
        _videoBIMQueue = _imgBIMQueue;
    }
}

@end
