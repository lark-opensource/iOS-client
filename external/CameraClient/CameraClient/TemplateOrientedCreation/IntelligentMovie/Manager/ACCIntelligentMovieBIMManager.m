//
//  ACCIntelligentMovieBIMManager.m
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/22.
//

#import "ACCIntelligentMovieBIMManager.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCIntelligentMovieDataProvider.h"
#import "ACCMVPhotoCalculateOperation.h"
#import "ACCAlgorithmService.h"
#import <CreationKitInfra/ACCLogProtocol.h>

static NSInteger const ACCMomentMediaScanManagerMaxQueueCount = 2;
static NSInteger const ACCMomentMediaScanDefaultOperationCount = 50;


typedef void(^ACCIntelligentMovieAssetsProcessCompletion)(NSError *error);

@interface ACCIntelligentMovieBIMManager () <ACCMVPhotoCalculateOperationDelegate>

@property (nonatomic, strong) ACCAlgorithmService *algorithmService;

@property (nonatomic, strong) VEAIMomentAlgorithm *videoAlgorithm;
@property (nonatomic, strong) VEAIMomentAlgorithm *imageAlgorithm;

@property (atomic, assign) NSUInteger curValidScanCount;

@property (atomic, assign) NSUInteger perValidScanCount;

@property (nonatomic, assign) NSUInteger curScanDate;

@property (nonatomic, strong) ACCIntelligentMovieDataProvider *dataProvider;

@property (nonatomic, strong) NSOperationQueue *imgBIMQueue;

@property (nonatomic, strong) NSOperationQueue *videoBIMQueue;

@property (atomic, assign) NSInteger curScanPageIdx;

@property (nonatomic, copy  ) NSArray<dispatch_queue_t> *imageQueues;

@property (nonatomic, strong) dispatch_queue_t commonQueue;

@property (nonatomic, strong) ACCMomentMediaAsset *lastAsset;

@property (nonatomic, copy) ACCIntelligentMovieAssetsProcessCompletion processCompletion;

@end

@implementation ACCIntelligentMovieBIMManager

- (instancetype)initWithAlgorithmService:(ACCAlgorithmService *)algorithmService
{
    self = [super init];
    
    if (self) {
        _algorithmService = algorithmService;
        
        _dataProvider = [[ACCIntelligentMovieDataProvider alloc] init];
       
        {
            _multiThreadOptimize = YES;
            _scanQueueOperationCount = ACCMomentMediaScanDefaultOperationCount;
            
            _imgBIMQueue = [[NSOperationQueue alloc] init];
            _imgBIMQueue.maxConcurrentOperationCount = ACCMomentMediaScanManagerMaxQueueCount;
            
            _videoBIMQueue = [[NSOperationQueue alloc] init];
            _videoBIMQueue.maxConcurrentOperationCount = 1;
        }
    }
    
    return self;
}

- (NSArray<dispatch_queue_t> *)imageQueues
{
    if (!_imageQueues) {
        NSMutableArray *tmp = [[NSMutableArray alloc] init];
        
        for (NSInteger i = 0; i < ACCMomentMediaScanManagerMaxQueueCount; i++) {
            NSString *name = [@"com.acc.moment.calculate.image.op" stringByAppendingFormat:@"%ld", (long)i];
            dispatch_queue_t oneQueue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
            [tmp acc_addObject:oneQueue];
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

- (void)startAnalyseSelecteAssetsFeature:(void (^)(BOOL success))completion
{
    // Only when the model is configured can analysis begin
    if (self.algorithmService == nil) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    if (![self.algorithmService isBIMModelReady]) {
        [self.algorithmService updateBIMModelWithCompletion:^(BOOL success) {
            if (success) {
                [self processSelectedMedia:^(NSError *error) {
                    if (error) {
                        AWELogToolError(AWELogToolTagMoment, @"process sssets error when analyse materials after update bim: %@", error);
                    }
                    if (completion) {
                        BOOL processSucces = (error == nil);
                        completion(processSucces);
                    }
                }];
            } else {
                if (completion) {
                    completion(success);
                }
            }
        }];
    } else {
        [self processSelectedMedia:^(NSError *error) {
            if (error) {
                AWELogToolError(AWELogToolTagMoment, @"process sssets error when analyse materials for bim ready: %@", error);
            }
            if (completion) {
                BOOL processSucces = (error == nil);
                completion(processSucces);
            }
        }];
    }
}

#pragma mark - Private Methods
- (void)processSelectedMedia:(void (^)(NSError *error))completion
{
    @weakify(self);
    
    self.curScanDate = [[NSDate date] timeIntervalSince1970] * 1000;
    self.processCompletion = completion;
    
    [self.dataProvider updateAssetResult:self.selectedAssets
                                scanDate:self.curScanDate
                              completion:^(NSError * _Nullable error) {
        if (error) {
            AWELogToolError(AWELogToolTagMoment, @"process sssets error when update DB: %@", error);
        }
        @strongify(self);
        if (error) {
            [self.videoBIMQueue cancelAllOperations];
            [self.imgBIMQueue cancelAllOperations];
        } else {
            [self restartCalculatePhotosFromDatabase];
        }
    }];
}

- (void)restartCalculatePhotosFromDatabase
{
    [self.dataProvider cleanPrepareAssetsWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            AWELogToolError(AWELogToolTagMoment, @"clean prepare sssets error for restart calculate: %@", error);
        }
    }];
    self.curScanPageIdx = 0;
    self.curValidScanCount = 0;
    self.lastAsset = nil;
    [self calculatePhotosFromDatabase];
}

- (void)calculatePhotosFromDatabase
{
    @weakify(self);
    [self.dataProvider loadPrepareAssetsWithLimit:self.scanQueueOperationCount
                                        pageIndex:self.curScanPageIdx
                                      resultBlock:^(NSArray<ACCMomentMediaAsset *> * _Nullable result,
                                                    NSUInteger allTotalCount,
                                                    BOOL endFlag) {
        @strongify(self);
        NSInteger totalCount = result.count;
        
        if (totalCount == 0) {
            // completion
            self.processCompletion(nil);
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
                    if (self.processCompletion) {
                        self.processCompletion(error);
                    }
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
                        if (error) {
                            AWELogToolError(AWELogToolTagMoment, @"clean prepare sssets error after finishing calculate: %@", error);
                        }
                    }];
                }
                
                if (endFlag ||
                    curIdx > lastIdx) {
                    
                    if (!endFlag) {
                        [self calculatePhotosFromDatabase];
                    }
                } else {
                    self.curScanPageIdx += 1;
                    [self calculatePhotosFromDatabase];
                }
            }
        };
        
        NSInteger __block imageQueueCount = 0;
        BOOL useMultiThread =  self.multiThreadOptimize;
        [result enumerateObjectsUsingBlock:^(ACCMomentMediaAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
            @strongify(self);
            ACCMVPhotoCalculateOperation *op = [[ACCMVPhotoCalculateOperation alloc] init];
            op.opDelegate = self;
            op.asset = asset;
            op.algorithmType = VEAIAlgorithmType_TemplateRecommend;
            op.aiAlgorithm = (asset.mediaType == PHAssetMediaTypeVideo) ? self.videoAlgorithm : self.imageAlgorithm;
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
            
            op.bimCompletion = ^(ACCMVPhotoCalculateOperationResult * _Nullable result) {
                if (result.bimResult) {
                    NSMutableArray *arr = [[NSMutableArray alloc] init];
                    ACCMomentBIMResult *bim = [[ACCMomentBIMResult alloc] initWithVEBIM:result.bimResult];
                    bim.orientation = result.orientation;
                    bim.imageExif = result.imageExif;
                    bim.videoCreateDateString = result.videoCreateDateString;
                    bim.videoModelString = result.videoModelString;
                    [bim configWithAssetModel:asset];
                    if (bim) {
                        [arr acc_addObject:bim];
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

#pragma mark - lazy

- (VEAIMomentAlgorithm *)videoAlgorithm
{
    if (!_videoAlgorithm) {
        NSInteger serviceCount = self.multiThreadOptimize ? (ACCMomentMediaScanManagerMaxQueueCount + 1) : 1;
        _videoAlgorithm = [[VEAIMomentAlgorithm alloc] initWithresourceFinder:[IESMMParamModule getResourceFinder]
                                                                 serviceCount:serviceCount
                                                                  superParams:VEAIMomentBIMModelTemplateRecommendVideoSpecialFrame];
    }
    return _videoAlgorithm;
}

- (VEAIMomentAlgorithm *)imageAlgorithm {
    if (!_imageAlgorithm) {
        NSInteger serviceCount = self.multiThreadOptimize ? (ACCMomentMediaScanManagerMaxQueueCount + 1) : 1;
        _imageAlgorithm = [[VEAIMomentAlgorithm alloc] initWithresourceFinder:[IESMMParamModule getResourceFinder]
                                                                 serviceCount:serviceCount
                                                                  superParams:VEAIMomentBIMModelTemplateRecommendImage];
    }
    return _imageAlgorithm;
}

- (BOOL)isOpBIMModelReady
{
    if (self.algorithmService == nil) return NO;
    return [self.algorithmService isBIMModelReady];
}

@end
