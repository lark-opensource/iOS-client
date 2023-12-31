//
//  BDAnimatedImagePlayer.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/29.
//

#import "BDAnimatedImagePlayer.h"
#import "BDImage.h"
#import <pthread.h>
#import <mach/mach.h>
#import "UIImage+BDWebImage.h"

static int64_t BDDeviceMemoryTotal() {
    int64_t mem = [[NSProcessInfo processInfo] physicalMemory];
    if (mem < -1) mem = -1;
    return mem;
}

static int64_t BDDeviceMemoryAvailable() {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t page_size;
    vm_statistics_data_t vm_stat;
    kern_return_t kern;
    
    kern = host_page_size(host_port, &page_size);
    if (kern != KERN_SUCCESS) return -1;
    kern = host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    if (kern != KERN_SUCCESS) return -1;
    return (vm_stat.free_count + vm_stat.inactive_count) * page_size;
}

@interface BDPlayerWeakProxy : NSObject
@property (nonatomic, weak) id target;
@end

@implementation BDPlayerWeakProxy
- (instancetype)initWithTarget:(id)target
{
    self = [super init];
    if (self) {
        _target = target;
    }
    return self;
}
- (void)nextFrame {
    if ([self.target respondsToSelector:@selector(nextFrame)]) {
        [self.target nextFrame];
    }
}
@end

@interface BDAnimatedImagePlayer ()
{
    NSUInteger _currentLoop;
    
    NSMutableDictionary *_frameCaches;
    NSMutableIndexSet *_cachedIndexes;
    
    CADisplayLink *_displayLink;
    dispatch_queue_t _frame_prefetch_queue;
    pthread_mutex_t _cache_lock;
    
    NSMutableIndexSet *_taskIndexes;
    pthread_mutex_t _task_lock;
    
    BOOL _cancelPrefetch;
    BOOL _needCaculateMaxFrameCount;
    BOOL postiveOrderFlag; // 正序逆序控制
    
    BOOL isDelayForDownloadFlag;    // 控制下载慢导致卡顿的标志
}

@property (nonatomic, assign) NSUInteger maxFrameCache;
@property (atomic, strong) BDImage *image;

@end

@implementation BDAnimatedImagePlayer
- (instancetype)initWithImage:(BDImage *)image
{
    self = [super init];
    if (self) {
        self.frameCacheAutomatically = YES;
        postiveOrderFlag = YES;
        _animateRunLoopMode = NSRunLoopCommonModes;
        if ([image isAnimateImage]) {
            if ((image.codeType == BDImageCodeTypeWebP || image.codeType == BDImageCodeTypeHeif) && image.animatedImageData && !image.bd_loading) {
                BDImageDecoderConfig *config = image.decoder.config;
                self.image = [BDImage imageWithData:image.animatedImageData
                                          scale:config.scale decodeForDisplay:config.decodeForDisplay shouldScaleDown:config.shouldScaleDown downsampleSize:config.downsampleSize cropRect:config.cropRect error:nil];
                self.image.bd_loading = image.bd_loading;
                self.image.bd_requestKey = image.bd_requestKey;
                self.image.bd_webURL = image.bd_webURL;
                self.image.bd_isDidScaleDown = image.bd_isDidScaleDown;
            } else {
                self.image = image;
            }
            if (self.image.bd_loading) {
                _loopCount = 1;
            } else {
                _loopCount = [image loopCount];
            }
        } else {
            return nil;
        }
        pthread_mutex_init(&_cache_lock, 0);
        _frameCaches = [NSMutableDictionary dictionary];
        _cachedIndexes = [NSMutableIndexSet indexSet];
        
        pthread_mutex_init(&_task_lock, 0);
        _taskIndexes = [NSMutableIndexSet indexSet];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

+ (instancetype)playerWithImage:(BDImage *)image
{
    return [[self alloc] initWithImage:image];
}

- (void)updateProgressImage:(BDImage *)image
{
    if (!image) {
        return;
    }
    if (![image.bd_requestKey isEqual:self.image.bd_requestKey]) {
        return;
    }
    if (image != self.image) {
        if (image.codeType == BDImageCodeTypeWebP || image.codeType == BDImageCodeTypeHeif) {
            [self.image changeImageWithData:image.animatedImageData finished:YES];
            self.image.bd_loading = NO;
            _loopCount = self.customLoopCount ? : [image loopCount];
            [self startPlay];
            return;
        }else {
            self.image = image;
        }
    }
    if (self.image.bd_loading) {
        _loopCount = 1;
    } else {
        _loopCount = self.customLoopCount ? : [image loopCount];
    }
    [self startPlay];
}

- (dispatch_queue_t)frame_prefetch_queue
{
    if (!_frame_prefetch_queue) {
        _frame_prefetch_queue = dispatch_queue_create("com.bd.image_frame_fetch_queue", DISPATCH_QUEUE_SERIAL);
    }
    return _frame_prefetch_queue;
}

- (NSUInteger)maxFrameCache
{
    if (_maxFrameCache == 0) {
        _maxFrameCache = 1;
    }
    return _maxFrameCache;
}

- (void)startPlay
{
    if (_isPlaying) {
        return;
    }
    _isPlaying = YES;
    
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:[[BDPlayerWeakProxy alloc] initWithTarget:self] selector:@selector(nextFrame)];
    }
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:self.animateRunLoopMode];
    [_displayLink setPaused:NO];
    //这里是为了防止self野指针的问题，因为self为__unsafe_unretained,外部持有BDAnimatedImagePlayer,并置空后可能会引起crash
    __strong __typeof(self)strongSelf = self;
    if ([_delegate respondsToSelector:@selector(imagePlayerStartPlay:)]) {
        [_delegate imagePlayerStartPlay:strongSelf];
    }
    if (self.frameCacheAutomatically) {
        [self calculateMaxCacheCount];
    } else {
        self.maxFrameCache = 1;
    }
    [self prefetchNextFrameIfNeed];
}

- (void)pause
{
    _isPlaying = NO;
    [_displayLink setPaused:YES];
}

- (void)stopPlay
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
    //防止调用方设置本类对象为空导致的野指针问题
    //即由于self为__unsafe_unretain 因此self为空后，会变为野指针，当对野指针进行写操作会crash「即150行」
    __strong __typeof(self)strongSelf = self;
#pragma clang diagnostic pop
    [_displayLink invalidate];
    _displayLink = nil;
    if (_isPlaying) {
        _isPlaying = NO;
        //这里是为了防止self野指针的问题，因为self为__unsafe_unretained,外部持有BDAnimatedImagePlayer,并置空后可能会引起crash
        __strong __typeof(self)strongSelf = self;
        if ([_delegate respondsToSelector:@selector(imagePlayerDidStopPlay:)]) {
            [_delegate imagePlayerDidStopPlay:strongSelf];
        }
    }
    
    if (!self.image.bd_loading) {
        self.currentFrame = nil;
        [self resetFrameCache];
        _currentLoop = 0;
    }
}

- (void)calculateMaxCacheCount
{
    CGImageRef cgImage = self.image.CGImage;
    int64_t rowBytes = CGImageGetBytesPerRow(cgImage);
    if (rowBytes == 0) {
        rowBytes = 4 * CGImageGetWidth(cgImage);
    }
    int64_t frameBytes = rowBytes * CGImageGetHeight(cgImage);
    
    int64_t total = BDDeviceMemoryTotal();
    int64_t free = BDDeviceMemoryAvailable();
    if (total <= 0 || free <= 0) {
        self.maxFrameCache = 1;
        return;
    }

    float ratio = MAX(0.2, (float)free / total);

    int64_t avaliable = MIN(20 * 1024 * 1024,free * ratio);
    if (frameBytes == 0) {
        self.maxFrameCache = 1;
        _needCaculateMaxFrameCount = NO;
        return;
    }
    NSUInteger maxCount = avaliable/frameBytes;
    self.maxFrameCache = MAX(1, maxCount);
    _needCaculateMaxFrameCount = NO;
}

- (void)nextFrame
{
    if (_isPlaying && _displayLink.timestamp >= self.currentFrame.nextFrameTime) {
        NSUInteger nextFrame = 0;
        if (self.animationType == BDAnimatedImageAnimationTypeOrder) {
            nextFrame = _currentFrame ? _currentFrame.index + 1 : 0;
            if ( nextFrame >= [self.image frameCount]) {
                if (!self.image.bd_loading &&
                    [self.delegate respondsToSelector:@selector(imagePlayerDidReachEnd:)]) {
                    [self.delegate imagePlayerDidReachEnd:self];
                }
                if ((_loopCount == 0 || _loopCount > _currentLoop + 1)) {
                    nextFrame = 0;
                    _currentLoop++;
                } else {
                    if(self.image.bd_loading && _delegate && [_delegate respondsToSelector:@selector(imagePlayerDelayPlay:index:animationDelayType:animationDelayState:)]){
                        // 如果下一帧的数据在上一帧播放完成后还没有来，那么就会走这里的卡顿逻辑
                        BDProgressiveAnimatedImageDelayType delayType = isDelayForDownloadFlag ? BDAnimatedImageDelayTypeDownload : BDAnimatedImageDelayTypeDecode;
                        [_delegate imagePlayerDelayPlay:self
                                                  index:nextFrame
                                     animationDelayType:delayType
                                    animationDelayState:BDAnimatedImageDelayStateGetDataAfterPlay];
                        isDelayForDownloadFlag = NO;
                    }
                        
                    // 播放完用户指定的次数
                    if ([self.delegate respondsToSelector:@selector(imagePlayerDidReachAllLoopEnd:)]){
                        [self.delegate imagePlayerDidReachAllLoopEnd:self];
                    }
                    [self stopPlay];
                    return;
                }
            }
        } else {
            NSInteger maxIndex = [self.image frameCount] - 1;
            if (_currentFrame.index == 0) {
                postiveOrderFlag = YES;
            }
            if (_currentFrame.index == maxIndex) {
                postiveOrderFlag = NO;
            }
            if (postiveOrderFlag) {
                nextFrame = _currentFrame.index + 1;
            } else {
                nextFrame = _currentFrame.index - 1;
            }
        }
        
        if (pthread_mutex_trylock(&_cache_lock) != 0) {
            return;
        }
        BDAnimateImageFrame *frame = [_frameCaches objectForKey:@(nextFrame)];
        BOOL mustCacheAllFrame = self.animationType == BDAnimatedImageAnimationTypeReciprocating && (self.image.codeType == BDImageCodeTypeWebP || self.image.codeType == BDImageCodeTypeHeif);
        if ((!mustCacheAllFrame && !self.cacheAllFrame && frame && self.image.frameCount > self.maxFrameCache) ||
            self.image.bd_loading) {
            [_frameCaches removeObjectForKey:@(nextFrame)];
            [_cachedIndexes removeIndex:nextFrame];
        }
        pthread_mutex_unlock(&_cache_lock);
        
        if (frame){
            CFTimeInterval preFrameTime = self.currentFrame.nextFrameTime;
            if (preFrameTime < frame.delay || preFrameTime + frame.delay < _displayLink.timestamp) {
                // 第一帧没有上一帧的时间，用当前时间
                //上一帧的时候与当时时间差太多，用当前时间
                preFrameTime = _displayLink.timestamp;
            }
            self.currentFrame = frame;
            self.currentFrame.nextFrameTime = preFrameTime + frame.delay;
            if(_delegate) {
                [_delegate imagePlayer:self didUpdateImage:frame.image index:nextFrame];
            }
        }else{
            if(self.image.bd_loading && _delegate && [_delegate respondsToSelector:@selector(imagePlayerDelayPlay:index:animationDelayType:animationDelayState:)]){
                // 如果下一帧的数据在上一帧播放的过程中来了，那么就会走这里的卡顿逻辑
                BDProgressiveAnimatedImageDelayType delayType = isDelayForDownloadFlag ? BDAnimatedImageDelayTypeDownload : BDAnimatedImageDelayTypeDecode;
                [_delegate imagePlayerDelayPlay:self
                                          index:nextFrame
                             animationDelayType:delayType
                            animationDelayState:BDAnimatedImageDelayStateGetDataDuringPlay];
                isDelayForDownloadFlag = NO;
            }
        }
        [self prefetchNextFrameIfNeed];
    }
}

- (void)prefetchNextFrameIfNeed
{
    if (_needCaculateMaxFrameCount && self.frameCacheAutomatically) {
        [self calculateMaxCacheCount];
    }
    _cancelPrefetch = NO;
    NSUInteger nextFrame = 0;
    if (self.animationType == BDAnimatedImageAnimationTypeOrder) {
        nextFrame = _currentFrame ? _currentFrame.index + 1 : 0;
        if (nextFrame >= [self.image frameCount]) {
            if (_loopCount == 0 || _loopCount > _currentLoop + 1) {
                nextFrame = 0;
            } else {
                // 设置下载卡顿标志
                isDelayForDownloadFlag = YES;
                return;
            }
        }
    } else {
        NSInteger maxIndex = [self.image frameCount] - 1;
        if (_currentFrame.index == 0) {
            postiveOrderFlag = YES;
        }
        if (_currentFrame.index == maxIndex) {
            postiveOrderFlag = NO;
        }
        if (postiveOrderFlag) {
            nextFrame = _currentFrame.index + 1;
        } else {
            nextFrame = _currentFrame.index - 1;
        }
    }
    // 通过 _taskIndexes 给解码的task作唯一标识，保证不会重复发起同一个解码 task
    pthread_mutex_lock(&_task_lock);
    if ([_taskIndexes containsIndex:nextFrame]) {
        pthread_mutex_unlock(&_task_lock);
        return;
    }
    [_taskIndexes addIndex:nextFrame];
    pthread_mutex_unlock(&_task_lock);
    
    dispatch_async([self frame_prefetch_queue], ^{
        [self prefetchNextFrame:nextFrame];
    });
}

- (void)prefetchNextFrame:(NSUInteger)nextFrame {
    BOOL needDecode = YES;
    pthread_mutex_lock(&_cache_lock);
    needDecode = ![_cachedIndexes containsIndex:nextFrame] && _frameCaches.count < self.image.frameCount;
    if (!needDecode || _cancelPrefetch) {
        pthread_mutex_lock(&_task_lock);
        [_taskIndexes removeIndex:nextFrame];
        pthread_mutex_unlock(&_task_lock);
        pthread_mutex_unlock(&_cache_lock);
        return;
    }
    BDAnimateImageFrame *frame = [self.image frameAtIndex:nextFrame];
    frame.index = nextFrame;
    if (frame) {
        [_frameCaches setObject:frame forKey:@(nextFrame)];
        [_cachedIndexes addIndex:nextFrame];
    }
    pthread_mutex_lock(&_task_lock);
    [_taskIndexes removeIndex:nextFrame];
    pthread_mutex_unlock(&_task_lock);
    pthread_mutex_unlock(&_cache_lock);
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [self resetFrameCache];
}

- (void)didEnterBackground:(NSNotification *)notification {
    [_displayLink setPaused:YES];
    [self resetFrameCache];
}

- (void)didBecomeActive:(NSNotification *)notification
{
    if (_displayLink) {
        [_displayLink setPaused:NO];
    }
    _needCaculateMaxFrameCount = YES;
}

- (void)resetFrameCache
{
    _cancelPrefetch = YES;
    _needCaculateMaxFrameCount = YES;
    // 这个地方在主线程调用，可能因为 decode task 卡住主线程
    if (pthread_mutex_trylock(&_cache_lock) != 0) {
        return;
    }
    
    if (!_isPlaying) {
        [_cachedIndexes removeAllIndexes];
        [_frameCaches removeAllObjects];
    } else {
        NSUInteger nextFrame = self.currentFrame?self.currentFrame.index + 1 : 0;
        if (nextFrame >= [self.image frameCount]) {
            if ((_loopCount == 0 || _loopCount > _currentLoop + 1)) {
                nextFrame = 0;
            }
        }
        for (NSNumber *number in _frameCaches.allKeys) {
            NSInteger index = [number unsignedIntegerValue];
            if (index < nextFrame) {
                [_frameCaches removeObjectForKey:number];
                [_cachedIndexes removeIndex:index];
            }
        }
    }
    pthread_mutex_unlock(&_cache_lock);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _delegate = nil;
    [self stopPlay];
    pthread_mutex_destroy(&_cache_lock);
}
@end
