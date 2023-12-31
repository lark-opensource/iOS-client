//
//  ACCMomentPhotoCalculateOperation.m
//  Pods
//
//  Created by Pinka on 2020/5/22.
//

#import "ACCMomentPhotoCalculateOperation.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCMomentUtil.h"
#import <CreativeKit/ACCMonitorProtocol.h>

#import <TTVideoEditor/VEVideoFramesGenerator.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectSDK_iOS/RequirementDefine.h>
#import "ACCExifUtil.h"

static CGFloat const ACCMomentPhotoTargetSize = 540;
static CGFloat const ACCMomentPhotoTargetiCloudSize = 300;

static NSString *const ACCMomentPhotoCalculateOperationErrorDomain = @"acc.ACCMomentPhotoCalculateOperation";
static NSInteger const ACCMomentPhotoCalculateOperationMissResultErrorCode = -2;
static NSInteger const ACCMomentPhotoCalculateOperationBIMNotReadyErrorCode = -999;

@implementation ACCMomentPhotoCalculateOperationResult

@end

@interface ACCMomentPhotoCalculateOperation ()

#pragma mark - NSOperation Override Properties
@property (readonly, getter=isCancelled) BOOL cancelled;
@property (readwrite, getter=isExecuting) BOOL executing;
@property (readwrite, getter=isFinished) BOOL finished;

#pragma mark -
@property (nonatomic, strong) NSRecursiveLock *stateLock;

@property (nonatomic, assign) PHImageRequestID requestId;

@property (nonatomic, strong) VEVideoFramesGenerator *frameGenerator;

@property (nonatomic, strong) NSDictionary *imageExif;

@property (nonatomic, copy  ) NSString *videoModelString;

@property (nonatomic, copy  ) NSString *videoCreateDateString;

@property (nonatomic, strong) VEAIMomentBIMResult *bimResult;

@property (nonatomic, strong) NSError *bimError;

@property (nonatomic, assign) NSUInteger orientation;

@end

@implementation ACCMomentPhotoCalculateOperation
@synthesize executing = _executing, finished = _finished, cancelled = _cancelled;

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _stateLock = [[NSRecursiveLock alloc] init];
    }
    
    return self;
}

#pragma mark - NSOperation Override Methods
- (void)start
{
    self.executing = YES;
    
    @weakify(self);
    PHAsset *phAsset = nil;
    if (self.asset.localIdentifier.length) {
        phAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[self.asset.localIdentifier] options:nil].firstObject;
    }
    
    if (PHAssetMediaTypeImage == self.asset.mediaType && phAsset) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        option.networkAccessAllowed = NO;
        option.synchronous = YES;
        
        self.requestId =
        [[PHImageManager defaultManager]
         requestImageForAsset:phAsset
         targetSize:CGSizeMake(ACCMomentPhotoTargetSize, ACCMomentPhotoTargetSize)
         contentMode:PHImageContentModeAspectFill
         options:option
         resultHandler:^(UIImage *result, NSDictionary *info) {
            @strongify(self);
            if (!self) {
                return;
            }
            
            BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
            if (isDegraded) {
                return;
            }
            
            void (^processBlock)(UIImage *) = ^(UIImage *theResult) {
                @strongify(self);
                dispatch_queue_t theQueue = self.calculateQueue;
                if (!theQueue) {
                    return;
                }
                
                dispatch_async(theQueue, ^{
                    @strongify(self);
                    if (self.isCancelled) {
                        dispatch_async(ACCMomentPhotoCalculateOperation.bimCallbackQueue, ^{
                            @strongify(self);
                            if (self.bimCompletion) {
                                self.bimCompletion(nil);
                            }
                            self.executing = NO;
                            self.finished = YES;
                        });
                        
                        return;
                    }
                    
                    // Check BIM Model
                    if (![self.class bimIsAlready]) {
                        self.bimError =
                        [NSError errorWithDomain:ACCMomentPhotoCalculateOperationErrorDomain code:ACCMomentPhotoCalculateOperationBIMNotReadyErrorCode userInfo:nil];
                        [self checkComplete];
                        return;
                    }
                    
                    CFAbsoluteTime ctime = CFAbsoluteTimeGetCurrent();
                    NSError *error;
                    VEAIMomentBIMResult *r = [self.aiAlgorithm getBIMInfoForImage:theResult
                                                                           config:ACCMomentPhotoCalculateOperation.imageBIMConfig
                                                                     serviceIndex:self.calculateIndex
                                                                            error:&error];
                    
                    CFAbsoluteTime gap = CFAbsoluteTimeGetCurrent() - ctime;
                    NSMutableDictionary *extra =
                    [NSMutableDictionary dictionaryWithDictionary:@{
                        @"duration": @(gap),
                        @"type": @"image"
                    }];
                    if (error.userInfo[VEAIMomentErrorCodeKey]) {
                        extra[@"moment_errorcode"] = error.userInfo[VEAIMomentErrorCodeKey];
                    }
                    
                    [ACCMonitor() trackService:@"moment_bim_access"
                                        status:r? 0: 1
                                         extra:extra];
                    
                    dispatch_async(ACCMomentPhotoCalculateOperation.bimCallbackQueue, ^{
                        @strongify(self);
                        self.bimResult = r;
                        self.bimError = error;
                        if (!r && !error) {
                            self.bimError =
                            [NSError errorWithDomain:ACCMomentPhotoCalculateOperationErrorDomain code:ACCMomentPhotoCalculateOperationMissResultErrorCode userInfo:nil];
                        }
                        
                        self.orientation = [ACCMomentUtil degressFromImage:result];
                        [self checkComplete];
                    });
                });
            };
            
            BOOL isICloud = [info[PHImageResultIsInCloudKey] boolValue];
            if (isICloud && !result) {
                PHImageRequestOptions *iCloudOptions = [[PHImageRequestOptions alloc] init];
                iCloudOptions.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
                iCloudOptions.networkAccessAllowed = YES;
                iCloudOptions.synchronous = YES;
                
                self.requestId =
                [[PHImageManager defaultManager]
                 requestImageForAsset:phAsset
                 targetSize:CGSizeMake(ACCMomentPhotoTargetiCloudSize, ACCMomentPhotoTargetiCloudSize)
                 contentMode:PHImageContentModeAspectFill
                 options:option
                 resultHandler:^(UIImage *iCloudResult, NSDictionary *info) {
                    if (iCloudResult) {
                        processBlock(iCloudResult);
                        return;
                    }
                    
                    dispatch_async(ACCMomentPhotoCalculateOperation.bimCallbackQueue, ^{
                        @strongify(self);
                        if (self.bimCompletion) {
                            self.bimCompletion(nil);
                        }
                        self.executing = NO;
                        self.finished = YES;
                    });
                }];
            } else {
                processBlock(result);
            }
        }];
        
        PHContentEditingInputRequestOptions *editOptions = [[PHContentEditingInputRequestOptions alloc] init];
        editOptions.networkAccessAllowed = NO;
        [phAsset requestContentEditingInputWithOptions:editOptions completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
            dispatch_async(ACCMomentPhotoCalculateOperation.bimCallbackQueue, ^{
                @strongify(self);
                NSDictionary *metadata = nil;
                if (contentEditingInput.fullSizeImageURL) {
                    metadata = contentEditingInput.fullSizeImageURL.acc_imageProperties;
                }
                
                self.imageExif = metadata[@"{Exif}"]? : @{};
                [self checkComplete];
            });
        }];
        
    } else if (PHAssetMediaTypeVideo == self.asset.mediaType && phAsset) {
        PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
        option.networkAccessAllowed = NO;
        if (@available(iOS 14.0, *)) {
            option.version = PHVideoRequestOptionsVersionCurrent;
            option.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        }
        
        [[PHImageManager defaultManager]
         requestAVAssetForVideo:phAsset
         options:option
         resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            @strongify(self);
            if (!self) {
                return;
            }
            
            dispatch_queue_t theQueue = self.calculateQueue;
            if (!theQueue) {
                return;
            }
            
            dispatch_async(theQueue, ^{
                @strongify(self);
                if (self.isCancelled) {
                    dispatch_async(ACCMomentPhotoCalculateOperation.bimCallbackQueue, ^{
                        @strongify(self);
                        if (self.bimCompletion) {
                            self.bimCompletion(nil);
                        }
                        self.executing = NO;
                        self.finished = YES;
                    });
                    
                    return;
                }
                
                if ([asset isKindOfClass:AVURLAsset.class]) {
                    AVURLAsset *urlAsset = (id)asset;
                    if ([urlAsset.availableMetadataFormats containsObject:AVMetadataFormatQuickTimeMetadata]) {
                        NSArray<AVMetadataItem *> *items = [urlAsset metadataForFormat:AVMetadataFormatQuickTimeMetadata];
                        [items enumerateObjectsUsingBlock:^(AVMetadataItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            @strongify(self);
                            if ([obj.identifier isEqualToString:AVMetadataIdentifierQuickTimeMetadataModel]) {
                                if ([obj.value isKindOfClass:NSString.class]) {
                                    self.videoModelString = (id)obj.value;
                                }
                            } else if ([obj.identifier isEqualToString:AVMetadataIdentifierQuickTimeMetadataCreationDate]) {
                                if ([obj.value isKindOfClass:NSString.class]) {
                                    self.videoCreateDateString = (id)obj.value;
                                }
                            }
                        }];
                    }
                    
                    [self.frameGenerator
                     generateFile:urlAsset.URL.path
                     range:[urlAsset tracksWithMediaType:AVMediaTypeVideo].firstObject.timeRange
                     fps:VEVideoFrameGeneratorFPS1
                     size:CGSizeMake(ACCMomentPhotoTargetSize, ACCMomentPhotoTargetSize)
                     imageCallback:^(UIImage * _Nonnull frame, NSTimeInterval time, NSInteger index, NSInteger total) {
                        @strongify(self);
                        if (!self) {
                            return;
                        }
                        
                        if (self.isCancelled) {
                            [self.frameGenerator cancel];
                            dispatch_async(ACCMomentPhotoCalculateOperation.bimCallbackQueue, ^{
                                @strongify(self);
                                if (self.bimCompletion) {
                                    self.bimCompletion(nil);
                                }
                                self.executing = NO;
                                self.finished = YES;
                            });
                            return;
                        }
                        
                        BOOL keyFlag = NO;
                        if (index == 0 || index+1 == total) {
                            keyFlag = YES;
                        } else if (index == total/2) {
                            keyFlag = YES;
                        }
                        
                        dispatch_queue_t theQueue = self.calculateQueue;
                        if (!theQueue) {
                            return;
                        }

                        dispatch_async(theQueue, ^{
                            @strongify(self);
                            if (self.isCancelled) {
                                return;
                            }
                            
                            // Check BIM Model
                            if (index == 0 &&
                                ![self.class bimIsAlready]) {
                                [self.frameGenerator cancel];
                                self.bimError =
                                [NSError errorWithDomain:ACCMomentPhotoCalculateOperationErrorDomain code:ACCMomentPhotoCalculateOperationBIMNotReadyErrorCode userInfo:nil];
                                [self checkComplete];
                                return;
                            }
                            
                            CFAbsoluteTime ctime = CFAbsoluteTimeGetCurrent();
                            NSError *error;
                            BOOL isLast = (index+1 == total);
                            VEAIMomentBIMResult *r =
                            [self.aiAlgorithm getBIMInfoForVideoFrame:frame
                                                           frameIndex:0
                                                              frameId:index
                                                            timeStamp:time
                                                               isLast:isLast
                                                               config:(keyFlag? ACCMomentPhotoCalculateOperation.videoKeyBIMConfig: ACCMomentPhotoCalculateOperation.videoNormalBIMConfig)
                                                         serviceIndex:self.calculateIndex
                                                                error:&error];
                            
                            if (isLast) {
                                CFAbsoluteTime gap = CFAbsoluteTimeGetCurrent() - ctime;
                                NSMutableDictionary *extra =
                                [NSMutableDictionary dictionaryWithDictionary:@{
                                    @"duration": @(gap),
                                    @"type": @"video"
                                }];
                                if (error.userInfo[VEAIMomentErrorCodeKey]) {
                                    extra[@"moment_errorcode"] = error.userInfo[VEAIMomentErrorCodeKey];
                                }
                                
                                [ACCMonitor() trackService:@"moment_bim_access"
                                                    status:r? 0: 1
                                                     extra:extra];
                                
                                dispatch_async(ACCMomentPhotoCalculateOperation.bimCallbackQueue, ^{
                                    @strongify(self);
                                    self.bimError = error;
                                    self.bimResult = r;
                                    
                                    if (!self.bimResult && !self.bimError) {
                                        self.bimError = [NSError errorWithDomain:ACCMomentPhotoCalculateOperationErrorDomain code:ACCMomentPhotoCalculateOperationMissResultErrorCode userInfo:nil];
                                    }
                                    self.orientation = [ACCMomentUtil aiOrientationFromDegress:[ACCMomentUtil degressFromAsset:asset]];
                                    [self checkComplete];
                                });
                            }
                        });
                    }
                     completion:^(BOOL result, NSError * _Nullable error) {
                        if (error) {
                            dispatch_async(ACCMomentPhotoCalculateOperation.bimCallbackQueue, ^{
                                @strongify(self);
                                self.bimError = error;
                                [self checkComplete];
                            });
                        }
                    }];
                } else {
                    dispatch_async(ACCMomentPhotoCalculateOperation.bimCallbackQueue, ^{
                        @strongify(self);
                        if (self.bimCompletion) {
                            self.bimCompletion(nil);
                        }
                        self.executing = NO;
                        self.finished = YES;
                    });
                    
                    return;
                }
            });
        }];
    } else {
        dispatch_async(ACCMomentPhotoCalculateOperation.bimCallbackQueue, ^{
            @strongify(self);
            if (self.bimCompletion) {
                self.bimCompletion(nil);
            }
            self.executing = NO;
            self.finished = YES;
        });
    }
}

- (void)cancel
{
    [self setCancelled:YES];
}

- (BOOL)isCancelled
{
    [_stateLock lock];
    BOOL flag = _cancelled;
    [_stateLock unlock];
    
    return flag;
}

- (void)setCancelled:(BOOL)cancelled
{
    [_stateLock lock];
    
    if (_cancelled != cancelled) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isCancelled))];
        _cancelled = cancelled;
        [self willChangeValueForKey:NSStringFromSelector(@selector(isCancelled))];
    }
    
    [_stateLock unlock];
}

- (BOOL)isExecuting
{
    [_stateLock lock];
    BOOL flag = _executing;
    [_stateLock unlock];
    
    return flag;
}

- (void)setExecuting:(BOOL)executing
{
    [_stateLock lock];
    
    if (_executing != executing) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
        _executing = executing;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    }
    
    [_stateLock unlock];
}

- (BOOL)isFinished
{
    [_stateLock lock];
    BOOL flag = _finished;
    [_stateLock unlock];
    
    return flag;
}

- (void)setFinished:(BOOL)finished
{
    [_stateLock lock];
    
    if (_finished != finished) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
        _finished = finished;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    }
    
    [_stateLock unlock];
}

- (BOOL)isReady
{
    return YES;
}

- (BOOL)isAsynchronous
{
    return (self.asset.mediaType == PHAssetMediaTypeImage);
}

- (BOOL)isConcurrent
{
    return (self.asset.mediaType == PHAssetMediaTypeImage);
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@"isExecuting"] ||
        [key isEqualToString:@"isFinished"] ||
        [key isEqualToString:@"isCancelled"]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

+ (void)setCrops:(NSArray<NSNumber *> *)crops
{
    NSArray<NSNumber *> *_crops = [crops copy];
    self.imageBIMConfig.aspectInfos = _crops;
    self.videoNormalBIMConfig.aspectInfos = _crops;
    self.videoKeyBIMConfig.aspectInfos = _crops;
}

+ (NSArray<NSNumber *> *)crops
{
    return self.imageBIMConfig.aspectInfos;
}

#pragma mark - Private Methods

+ (dispatch_queue_t)bimCallbackQueue
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.acc.moment.calculate.bim.callback", DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

+ (VEAIMomentBIMConfig *)imageBIMConfig
{
    static VEAIMomentBIMConfig *bimConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bimConfig = [[VEAIMomentBIMConfig alloc] init];
        bimConfig.runtimeSelectModels = VEAIMomentBIMModelImage;
        bimConfig.aspectInfos = @[@1.0, @2.0, @0.5];
    });
    
    return bimConfig;
}

+ (VEAIMomentBIMConfig *)videoNormalBIMConfig
{
    static VEAIMomentBIMConfig *bimConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bimConfig = [[VEAIMomentBIMConfig alloc] init];
        bimConfig.runtimeSelectModels = VEAIMomentBIMModelVideoNormalFrame;
        bimConfig.aspectInfos = @[@1.0, @2.0, @0.5];
    });
    
    return bimConfig;
}

+ (VEAIMomentBIMConfig *)videoKeyBIMConfig
{
    static VEAIMomentBIMConfig *bimConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bimConfig = [[VEAIMomentBIMConfig alloc] init];
        bimConfig.runtimeSelectModels = VEAIMomentBIMModelVideoKeyFrame;
        bimConfig.aspectInfos = @[@1.0, @2.0, @0.5];
    });
    
    return bimConfig;
}

- (VEVideoFramesGenerator *)frameGenerator
{
    if (!_frameGenerator) {
        _frameGenerator = [[VEVideoFramesGenerator alloc] init];
    }
    
    return _frameGenerator;
}

- (void)checkComplete
{
    if (PHAssetMediaTypeImage == self.asset.mediaType) {
        if ((self.bimResult || self.bimError) &&
            self.imageExif) {
            if (self.bimCompletion) {
                ACCMomentPhotoCalculateOperationResult *result = [[ACCMomentPhotoCalculateOperationResult alloc] init];
                result.bimResult = self.bimResult;
                result.orientation = self.orientation;
                result.imageExif = self.imageExif;
                result.error = self.bimError;
                
                self.bimCompletion(result);
            }
            
            self.executing = NO;
            self.finished = YES;
        }
    } else if (PHAssetMediaTypeVideo == self.asset.mediaType) {
        if (self.bimResult || self.bimError) {
            if (self.bimCompletion) {
                ACCMomentPhotoCalculateOperationResult *result = [[ACCMomentPhotoCalculateOperationResult alloc] init];
                result.bimResult = self.bimResult;
                result.orientation = self.orientation;
                result.videoModelString = self.videoModelString;
                result.videoCreateDateString = self.videoCreateDateString;
                result.error = self.bimError;
                
                self.bimCompletion(result);
            }
            
            self.executing = NO;
            self.finished = YES;
        }
    }
}

+ (BOOL)bimIsAlready
{
    return [EffectPlatform isRequirementsDownloaded:@[@REQUIREMENT_MOMENT_TAG]];
}

@end
