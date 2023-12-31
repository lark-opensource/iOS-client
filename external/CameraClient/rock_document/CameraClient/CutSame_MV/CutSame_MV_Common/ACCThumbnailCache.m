//
//  ACCThumbnailCache.m
//  ACCStudio
//
//  Created by Shen Chen on 2019/5/19.
//

#import "ACCThumbnailCache.h"
#import <CameraClient/AWEAssetModel.h>

@interface ACCThumbnailRequest()

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSMutableArray *completionBlocks;
@property (nonatomic, strong) NSOperation* operation;
@property (nonatomic, copy, nullable) void (^cancelBlock)(ACCThumbnailRequest *request);
@property (nonatomic, strong) NSLock *lock;

@end

@implementation ACCThumbnailRequest

- (instancetype)initWithKey:(NSString *)key cacheImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        _key = key;
        _fromCache = YES;
        _image = image;
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key completion: (void (^)(UIImage *image))completion cancel:(void (^)(ACCThumbnailRequest *request))cancelBlock
{
    self = [super init];
    if (self) {
        _key = key;
        _completionBlocks = [NSMutableArray new];
        self.cancelBlock = cancelBlock;
        if (completion) {
            [_completionBlocks addObject:completion];
        }
        _fromCache = NO;
        _image = nil;
    }
    return self;
}

- (NSLock *)lock {
    if (_lock == nil) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}

- (void)addCompletion:(void (^)(UIImage *image))completion
{
    if (completion) {
        [self.lock lock];
        [self.completionBlocks addObject:[completion copy]];
        [self.lock unlock];
    }
}

- (void)completeWithImage:(UIImage *)image
{
    _image = image;
    [self.lock lock];
    if (self.completionBlocks.count > 0) {
        NSArray *blocks = [self.completionBlocks copy];
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakself && !weakself.operation.isCancelled) {
                for (void (^block)(UIImage *image) in blocks) {
                    block(image);
                }
            }
        });
        [self.completionBlocks removeAllObjects];
    }
    [self.lock unlock];
}

- (void)cancel
{
    if (!self.operation.isCancelled) {
        [self.operation cancel];
    }
    [self.lock lock];
    [self.completionBlocks removeAllObjects];
    [self.lock unlock];
    if (self.cancelBlock) {
        self.cancelBlock(self);
    }
}

@end

@interface ACCThumbnailCache()

@property (nonatomic, strong) NSCache<NSString *, UIImage *> *memoryCache;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMutableDictionary *requestPool;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) NSMutableDictionary *generators;
//performance track
@property (nonatomic, strong, readwrite) NSMutableArray<NSNumber *> *generatorDurationArray;

@end

@implementation ACCThumbnailCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        _memoryCache = [[NSCache alloc] init];
        _memoryCache.name = @"thumbnail cache";
        _memoryCache.totalCostLimit = 200;
        _tolerance = 0.05;
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
        _queue.qualityOfService = NSQualityOfServiceUserInitiated;
        _requestPool = [NSMutableDictionary new];
        _generators = [NSMutableDictionary new];
        _dispatchQueue = dispatch_queue_create("acc_thumbnail_cache_queue", DISPATCH_QUEUE_SERIAL);
        _generatorDurationArray = @[].mutableCopy;
    }
    return self;
}


- (void)dealloc
{
    [self cancelAllRequests];
}

- (void)cancelAllRequests
{
    [self.queue cancelAllOperations];
    [self.requestPool removeAllObjects];
    [self.generators removeAllObjects];
}

- (UIImage *)cachedImageForKey:(NSString *)key orientation:(UIImageOrientation)orientation
{
    UIImage *image;
    UIImage *cached = [self.memoryCache objectForKey:key];
    if (cached == nil) {
        return cached;
    }
    if (orientation == cached.imageOrientation) {
        image = cached;
    } else {
        image = [UIImage imageWithCGImage:cached.CGImage scale:1.0 orientation:orientation];
        [self.memoryCache setObject:image forKey:key cost:1];
    }
    return image;
}

- (ACCThumbnailRequest *)getThumbnailForAsset:(AVAsset *)asset
                                       atTime:(CMTime)time
                                 preferedSize:(CGSize)size
                                     rotation:(ACCVideoCompositionRotateType)rotation
                                   completion:(void (^)(UIImage *image))completion
{
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    NSString *key = [self keyForAsset:asset atTime:time preferedSize:size];
    UIImageOrientation orientation = [self imageOrientationFromRotateType:rotation];
    // 如果是图片的占位视频
    if (asset.frameImageURL && asset.thumbImage) {
        UIImage *rotatedImage = [UIImage imageWithCGImage:asset.thumbImage.CGImage scale:1.0 orientation:orientation];
        if (completion) {
            completion(rotatedImage);
        }
        return [[ACCThumbnailRequest alloc] initWithKey:key cacheImage:rotatedImage];
    }
    UIImage *cached = [self cachedImageForKey:key orientation:orientation];
    if (cached != nil) {
        if (completion) {
            completion(cached);
        }
        return [[ACCThumbnailRequest alloc] initWithKey:key cacheImage:cached];
    } else {
        __block ACCThumbnailRequest *request;
        dispatch_sync(self.dispatchQueue, ^{
            request = self.requestPool[key];
        });
        if (request != nil && !request.operation.isCancelled) {
            if (completion != nil) {
                [request addCompletion:completion];
            }
            return request;
        }
        
        __weak typeof(self) weakself = self;
        request = [[ACCThumbnailRequest alloc] initWithKey:key completion:^(UIImage *image) {
            __strong typeof(self) strongself = weakself;
            [strongself.generatorDurationArray addObject:@(CFAbsoluteTimeGetCurrent() - start)];
            if (completion) {
                completion(image);
            }
        } cancel:^(ACCThumbnailRequest *request) {
            if (weakself.dispatchQueue != nil) {
                __strong typeof(self) strongself = weakself;
                dispatch_async(weakself.dispatchQueue, ^{
                    [strongself.requestPool removeObjectForKey:key];
                });
            }
        }];
        dispatch_async(self.dispatchQueue, ^{
            weakself.requestPool[key] = request;
            AVAssetImageGenerator *imageGenerator = weakself.generators[asset];
            if (imageGenerator == nil) {
                imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
                weakself.generators[asset] = imageGenerator;
            }
//            NSTimeInterval imageGeneratorBegin = CFAbsoluteTimeGetCurrent();
            imageGenerator.appliesPreferredTrackTransform = YES;
            CMTime tolerance = CMTimeMakeWithSeconds(weakself.tolerance, asset.duration.timescale);
            imageGenerator.requestedTimeToleranceAfter = tolerance;
            imageGenerator.requestedTimeToleranceBefore = tolerance;
            imageGenerator.maximumSize = size;
            CMTime requestedTime = time;
            CMTime duration = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject.timeRange.duration;

            if (time.value == 0 && time.timescale == 0) { // 这种情况 CMTimeCompare 返回 -1
                requestedTime = CMTimeMakeWithSeconds(0, duration.timescale);
            } else if (CMTimeCompare(time, duration) > 0) { // use last frame if requested time is beyond video's duration
                requestedTime = duration;
            }
            __strong typeof(self) strongself = weakself;
            request.operation = [NSBlockOperation blockOperationWithBlock:^{
                NSError *error = nil;
                CGImageRef imageRef = [imageGenerator copyCGImageAtTime:requestedTime actualTime:NULL error:&error];
                if (imageRef != nil && error == nil && strongself != nil) {
                    @autoreleasepool {
                        UIImage *generated = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:orientation];
                        [strongself.memoryCache setObject:generated forKey:key cost:1];
                        dispatch_async(strongself.dispatchQueue, ^{
                            ACCThumbnailRequest *req = strongself.requestPool[key];
                            if (req != nil) {
                                UIImage *image = [strongself cachedImageForKey:key orientation:orientation];
                                [req completeWithImage:image];
                            }
                            [strongself.requestPool removeObjectForKey:key];
                        });
                    }
                }
                CGImageRelease(imageRef);
            }];
            [self.queue addOperation:request.operation];
        });
        
        return request;
    }
}

- (NSString *)keyForAsset:(AVAsset *)asset atTime:(CMTime)time preferedSize:(CGSize)size
{
    NSString *key = [NSString stringWithFormat: @"%lu_%d_%d,%d", (unsigned long)asset.hash, (int)(CMTimeGetSeconds(time) * 1000), (int)size.width, (int)size.height];
    return key;
}

- (UIImageOrientation)imageOrientationFromRotateType:(ACCVideoCompositionRotateType) rotateType
{
    switch (rotateType) {
        case ACCVideoCompositionRotateTypeNone:
            return UIImageOrientationUp;
        case ACCVideoCompositionRotateTypeRight:
            return UIImageOrientationRight;
        case ACCVideoCompositionRotateTypeDown:
            return UIImageOrientationDown;
        case ACCVideoCompositionRotateTypeLeft:
            return UIImageOrientationLeft;
    }
}

@end
