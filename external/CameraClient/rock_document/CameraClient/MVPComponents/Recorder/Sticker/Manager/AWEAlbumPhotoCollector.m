//
//  AWEAlbumPhotoCollector.m
//  Pods
//
//  Created by zhangchengtao on 2019/6/27.
//

#import "AWEAlbumPhotoCollector.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import "CAKAlbumAssetModel+Convertor.h"
#import <TTVideoEditor/VEImageDetector.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeAlbumKit/CAKPhotoManager.h>

/**
 * 照片收集器的状态
 */
typedef NS_ENUM(NSInteger, AWEAlbumPhotoCollectorState) {
    AWEAlbumPhotoCollectorStateNotRunning = 0,
    AWEAlbumPhotoCollectorStateRunning = 1,
    AWEAlbumPhotoCollectorStateStopping = 2,
};

static const NSUInteger kDetectMaxCount = 200;
static const NSUInteger kResultSortCount = 30;


static NSString *kEffectConfigKeyFaceMin = @"face_count_min";
static NSString *kEffectConfigKeyFaceMax = @"face_count_max";

@interface AWEAlbumPhotoCollector ()

@property (nonatomic, strong) NSMutableArray<AWEAlbumImageModel *> *detectedAssetsModels;

@property (nonatomic) AWEAlbumPhotoCollectorState state;

@property (nonatomic, copy, readwrite) NSString *identifier;

@property (nonatomic, copy) NSArray<AWEAssetModel *> *assetModelArray;

@property (nonatomic) NSInteger assetModelArrayIndex;

@property (nonatomic) AWEGetResourceType detectType;

@end

@implementation AWEAlbumPhotoCollector

- (instancetype)initWithIdentifier:(nonnull NSString *)identifier {
    if (self = [super init]) {
        _detectedAssetsModels = [[NSMutableArray alloc] init];
        NSAssert(identifier.length, @"[pixaloop] Identifier must not be nil.");
        _identifier = [identifier copy];
        _state = AWEAlbumPhotoCollectorStateNotRunning;
        _assetModelArrayIndex = 0;
        _detectType = AWEGetResourceTypeImage;
        _maxDetectCount = kDetectMaxCount;
    }
    return self;
}

- (void)dealloc {
    AWELogToolDebug2(@"pixaloop",AWELogToolTagImport, @"collector<%@> dealloc", self.identifier);
}

- (NSArray<AWEAlbumImageModel *> *)detectedResult {
    return [self.detectedAssetsModels copy];
}

- (void)startDetect {
    if ([NSThread isMainThread]) {
        if (self.state == AWEAlbumPhotoCollectorStateRunning ||
            self.state == AWEAlbumPhotoCollectorStateStopping) {
            return;
        }
        self.state = AWEAlbumPhotoCollectorStateRunning;
        
        if ([self.observer respondsToSelector:@selector(collectorDidStartDetect:)]) {
            [self.observer collectorDidStartDetect:self];
        }
        
        if (self.assetModelArray.count > 0) {
            [self p_beginDetecting];
        } else {
            [CAKPhotoManager getAssetsWithType:self.detectType filterBlock:^BOOL(PHAsset *phAsset) {
                if (phAsset.pixelHeight == 0) {
                    return NO;
                }
                CGFloat ratio = ((CGFloat)phAsset.pixelWidth) / ((CGFloat)phAsset.pixelHeight);
                return 1.0/2.2 < ratio && ratio < 2.2;
            } completion:^(NSArray<CAKAlbumAssetModel *> *assetModelArray, PHFetchResult *result) {
                if (assetModelArray.count > 0) {
                    self.assetModelArray = [[[CAKAlbumAssetModel convertToStudioArray:assetModelArray] reverseObjectEnumerator] allObjects];
                    self.assetModelArrayIndex = 0;
                    [self p_beginDetecting];
                } else {
                    self.state = AWEAlbumPhotoCollectorStateNotRunning;
                    
                    if ([self.observer respondsToSelector:@selector(collectorDidFinishDetect:)]) {
                        [self.observer collectorDidFinishDetect:self];
                    }
                }
            }];
        }
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startDetect];
        });
    }
}

- (void)stopDetect {
    if ([NSThread isMainThread]) {
        if (self.state == AWEAlbumPhotoCollectorStateRunning) {
            self.state = AWEAlbumPhotoCollectorStateStopping;
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopDetect];
        });
    }
}

- (void)reset {
    if ([NSThread isMainThread]) {
        if (self.state == AWEAlbumPhotoCollectorStateNotRunning) {
            self.assetModelArray = nil;
            self.assetModelArrayIndex = 0;
            if (self.detectedAssetsModels.count > 0) {
                NSMutableArray *removeIndex = [[NSMutableArray alloc] initWithCapacity:self.detectedAssetsModels.count];
                for (NSInteger index = 0; index < self.detectedAssetsModels.count; index++) {
                    [removeIndex addObject:@(index)];
                }
                [self.detectedAssetsModels removeAllObjects];
                if ([self.observer respondsToSelector:@selector(collector:detectResultDidChange:)]) {
                    [self.observer collector:self detectResultDidChange:@{@"delete": [removeIndex copy]}];
                }
            }
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reset];
        });
    }
}

- (AWEAlbumImageModel * __nullable)imageFrom:(AWEAssetModel *)assetModel {
    // Subclass implement
    return nil;
}

- (void)p_beginDetecting {
    NSArray<AWEAssetModel *> *assetModels = self.assetModelArray;
    AWELogToolInfo2(@"AWEAlbumPhotoCollector", AWELogToolTagRecord, @" collector<%@> beginDetecting, assetModelArray:%@", self.identifier, @(assetModels.count));
    dispatch_queue_t detectingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(detectingQueue, ^{
        
        NSMutableArray *bucket = [[NSMutableArray alloc] initWithCapacity:6];
        NSInteger lastIndexCheckedFace = 0;
        BOOL finish = NO;
        while (self.state == AWEAlbumPhotoCollectorStateRunning) {
            NSInteger assetModelArrayIndex = self.assetModelArrayIndex;
            NSInteger targetCount = self.detectedAssetsModels.count;
            if (assetModelArrayIndex >= assetModels.count ||
                targetCount >= self.maxDetectCount) {
                finish = YES;
                break;
            }
            
            AWEAssetModel *assetModel = [assetModels objectAtIndex:assetModelArrayIndex];
            AWEAlbumImageModel *faceModel = [self imageFrom:assetModel];
            if (faceModel) {
                [bucket addObject:faceModel];
                if (bucket.count > 5 || assetModelArrayIndex - lastIndexCheckedFace > 5) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        NSInteger insertOffset = self.detectedAssetsModels.count;
                        NSMutableArray *insertIndex = [[NSMutableArray alloc] initWithCapacity:bucket.count];
                        for (NSInteger index = 0; index < bucket.count; index++) {
                            [insertIndex addObject:@(insertOffset + index)];
                        }
                        [self.detectedAssetsModels addObjectsFromArray:bucket];
                        if ([self.observer respondsToSelector:@selector(collector:detectResultDidChange:)]) {
                            [self.observer collector:self detectResultDidChange:@{@"insert": [insertIndex copy]}];
                        }
                    });
                    [bucket removeAllObjects];
                }
                lastIndexCheckedFace = assetModelArrayIndex;
            }
            
            self.assetModelArrayIndex++;
        }
        
        if (bucket.count > 0) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSInteger insertOffset = self.detectedAssetsModels.count;
                NSMutableArray *insertIndex = [[NSMutableArray alloc] initWithCapacity:bucket.count];
                for (NSInteger index = 0; index < bucket.count; index++) {
                    [insertIndex addObject:@(insertOffset + index)];
                }
                [self.detectedAssetsModels addObjectsFromArray:bucket];
                if ([self.observer respondsToSelector:@selector(collector:detectResultDidChange:)]) {
                    [self.observer collector:self detectResultDidChange:@{@"insert": [insertIndex copy]}];
                }
            });
            [bucket removeAllObjects];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // 退出检测
            self.state = AWEAlbumPhotoCollectorStateNotRunning;
            
            if (finish) {
                // 检测结束
                if ([self.observer respondsToSelector:@selector(collectorDidFinishDetect:)]) {
                    [self.observer collectorDidFinishDetect:self];
                }
            } else {
                // 手动暂停
                if ([self.observer respondsToSelector:@selector(collectorDidPauseDetect:)]) {
                    [self.observer collectorDidPauseDetect:self];
                }
            }
        });
    });
}

@end


#pragma mark - Pixaloop Photo Collector

@interface AWEAlbumPixaloopPhotoCollector ()

@property (nonatomic, copy, readwrite) NSArray<NSString *> *pixaloopAlg;
@property (nonatomic, copy, readwrite) NSString *pixaloopRelation;
@property (nonatomic, copy, readwrite) NSString *pixaloopImgK;
@property (nonatomic, strong) NSDictionary *pixaloopSDKExtra;
@property (nonatomic, strong) VEImageDetector *veImageDetector;
@property (atomic, assign) BOOL appTerminated;

@property (atomic, assign) BOOL needSortResult;

@end

@implementation AWEAlbumPixaloopPhotoCollector

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithIdentifier:(nonnull NSString *)identifier
                       pixaloopAlg:(nonnull NSArray<NSString *> *)pixaloopAlg
                  pixaloopRelation:(nonnull NSString *)pixaloopRelation
                      pixaloopImgK:(nonnull NSString *)pixaloopImgK
                  pixaloopSDKExtra:(nonnull NSDictionary *)pixaloopSDKExtra
{
    if (self = [super initWithIdentifier:identifier]) {
        _pixaloopAlg = [pixaloopAlg copy];
        _pixaloopRelation = [pixaloopRelation copy];
        _pixaloopImgK = [pixaloopImgK copy];
        _pixaloopSDKExtra = [pixaloopSDKExtra acc_dictionaryValueForKey:@"pl"];
        _veImageDetector = [[VEImageDetector alloc] init];
        
        if (_pixaloopSDKExtra[kEffectConfigKeyFaceMin] || _pixaloopSDKExtra[kEffectConfigKeyFaceMax]) {
            _needSortResult = YES;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    self.appTerminated = YES;
}

- (NSArray<AWEAlbumImageModel *> *)detectedResult
{
    if (self.needSortResult) {
        if (self.assetModelArrayIndex < kResultSortCount - 1 && self.assetModelArrayIndex < self.assetModelArray.count - 1 ) {
            return nil;
        } else {
            self.needSortResult = NO;
            
            [self.detectedAssetsModels sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(AWEAlbumImageModel *  _Nonnull obj1, AWEAlbumImageModel *  _Nonnull obj2) {
                if (obj1.detectResult == obj2.detectResult) {
                    return NSOrderedSame;
                } else {
                    return obj1.detectResult > obj2.detectResult ? NSOrderedAscending : NSOrderedDescending;
                }
            }];
        }
    }
    
    return [self.detectedAssetsModels copy];
}

- (AWEAlbumImageModel *)imageFrom:(AWEAssetModel *)assetModel
{
    // pixaloop图片识别过滤掉size太小的图片
    if (assetModel.asset.pixelWidth < 360.0f || assetModel.asset.pixelHeight < 480.0f) {
        return nil;
    }
    
    AWEAlbumPhotoCollectorDetectResult detectResult = [self isPixaloopSupportWithAsset:assetModel.asset];
    if (detectResult != AWEAlbumPhotoCollectorDetectResultUnmatch) {
        AWEAlbumImageModel *faceModel = [[AWEAlbumImageModel alloc] init];
        faceModel.assetLocalIdentifier = assetModel.asset.localIdentifier;
        faceModel.asset = assetModel;
        faceModel.detectResult = detectResult;
        return faceModel;
    }
    
    return nil;
}

- (AWEAlbumPhotoCollectorDetectResult)isPixaloopSupportWithAsset:(PHAsset *)asset
{
    if (!asset) {
        return AWEAlbumPhotoCollectorDetectResultUnmatch;
    }
    
    @autoreleasepool {
        __block AWEAlbumPhotoCollectorDetectResult isPixaloopSupport = AWEAlbumPhotoCollectorDetectResultUnmatch;
        CGSize targetSize = CGSizeMake(128, 224); //detect photo min size
        PHImageRequestOptions *option = [PHImageRequestOptions new];
        option.synchronous = YES; // Make sure synchronous is true.
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        option.networkAccessAllowed = NO;
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:targetSize
                                                  contentMode:PHImageContentModeAspectFill
                                                      options:option
                                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                    if (result) {
                                                        if (self.pixaloopAlg.count > 0) {
                                                            if (self.appTerminated) {
                                                                // detect queue is not main queue, need interception
                                                                return;
                                                            }
                                                            if ([self.pixaloopRelation isEqualToString:@"and"]) {
                                                                isPixaloopSupport = AWEAlbumPhotoCollectorDetectResultMatch;
                                                                for (NSString *alg in self.pixaloopAlg) {
                                                                    if (self.appTerminated) {
                                                                        // detect queue is not main queue, need interception
                                                                        isPixaloopSupport = AWEAlbumPhotoCollectorDetectResultUnmatch;
                                                                        return;
                                                                    }
                                                                    AWEAlbumPhotoCollectorDetectResult detectResult = [self detectImage:result withAlgorithm:alg extra:self.pixaloopSDKExtra];
                                                                    if (detectResult == AWEAlbumPhotoCollectorDetectResultUnmatch) {
                                                                        isPixaloopSupport = AWEAlbumPhotoCollectorDetectResultUnmatch;
                                                                        break;
                                                                    }
                                                                    
                                                                    if (detectResult == AWEAlbumPhotoCollectorDetectResultPerfectMatch) {
                                                                        isPixaloopSupport = AWEAlbumPhotoCollectorDetectResultPerfectMatch;
                                                                    }
                                                                }
                                                            } else {
                                                                isPixaloopSupport = AWEAlbumPhotoCollectorDetectResultUnmatch;
                                                                for (NSString *alg in self.pixaloopAlg) {
                                                                    if (self.appTerminated) {
                                                                        // detect queue is not main queue, need interception
                                                                        isPixaloopSupport = AWEAlbumPhotoCollectorDetectResultUnmatch;
                                                                        return;
                                                                    }
                                                                    AWEAlbumPhotoCollectorDetectResult detectResult = [self detectImage:result withAlgorithm:alg extra:self.pixaloopSDKExtra];
                                                                    if (detectResult != AWEAlbumPhotoCollectorDetectResultUnmatch) {
                                                                        isPixaloopSupport = detectResult;
                                                                        break;
                                                                    }
                                                                }
                                                            }
                                                        } else {
                                                            isPixaloopSupport = AWEAlbumPhotoCollectorDetectResultMatch;
                                                        }
                                                    }
                                                }];
        return isPixaloopSupport;
    }
}

- (AWEAlbumPhotoCollectorDetectResult)detectImage:(UIImage *)image withAlgorithm:(NSString *)algorithm extra:(NSDictionary *)config
{
    NSInteger itemCount = [self.veImageDetector detectPhoto:image withAlgorithm:algorithm];
    AWEAlbumPhotoCollectorDetectResult result = AWEAlbumPhotoCollectorDetectResultUnmatch;

    if (itemCount > 0) {
        result = AWEAlbumPhotoCollectorDetectResultPerfectMatch;
        if ([algorithm isEqual:@"face"] && (config[kEffectConfigKeyFaceMin] || config[kEffectConfigKeyFaceMax])) {
            if (config[kEffectConfigKeyFaceMin] && itemCount < [config[kEffectConfigKeyFaceMin] integerValue]) {
                result = AWEAlbumPhotoCollectorDetectResultMatch;
            }
            
            if (config[kEffectConfigKeyFaceMax] && itemCount > [config[kEffectConfigKeyFaceMax] integerValue]) {
                result = AWEAlbumPhotoCollectorDetectResultMatch;
            }
        }
    }
    
    return result;
}

@end

#pragma mark - Video Collector

@implementation AWEAlbumVideoCollector


- (instancetype)initWithIdentifier:(NSString *)identifier pixaloopVKey:(NSString *)pixaloopK pixaloopResourcePath:(NSString*)pixaloopResourcePath {
    if (self = [super initWithIdentifier:identifier]) {
        self.detectType = AWEGetResourceTypeVideo;
        _pixaloopVKey = pixaloopK;
        _pixaloopResourcePath = pixaloopResourcePath;
    }
    return self;
}

- (AWEAlbumImageModel *)imageFrom:(AWEAssetModel *)assetModel {
    
    /// Check AssetModel
    if (!assetModel.asset) {
        return nil;
    }
    /// Create FaceModels
    AWEAlbumImageModel *faceModel = [[AWEAlbumImageModel alloc] init];
    faceModel.asset = assetModel;
    faceModel.assetLocalIdentifier = assetModel.asset.localIdentifier;
    faceModel.networkAccessAllowed = YES;
    
    return faceModel;
}

@end

