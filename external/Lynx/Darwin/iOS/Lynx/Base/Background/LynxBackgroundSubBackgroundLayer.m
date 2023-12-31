// Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxBackgroundManager.h"
#import "LynxBackgroundUtils.h"
#import "LynxUI+Internal.h"
#import "LynxWeakProxy.h"

@interface LynxBackgroundSubBackgroundLayer () {
  bool _needCalculateInterval;
  double _singleFrameDuration;
  double _elapsedDuration;
}
@property(atomic, assign) BOOL isPreRendering;
@property(nonatomic, strong) CADisplayLink* displayLink;
@property(nonatomic, strong) NSMutableArray<UIImage*>* frameQueue;
@property(nonatomic, assign) CGSize viewSize;
@property(nonatomic, assign) LynxBorderRadii cornerRadii;
@property(nonatomic, assign) UIEdgeInsets borderInsets;
@property(nonatomic, strong) UIColor* layerBackgroundColor;
@property(nonatomic, assign) BOOL drawToEdge;
@property(nonatomic, assign) NSUInteger currentFrameIndex;
@property(nonatomic, assign) UIEdgeInsets capInsets;
@property(nonatomic, assign) BOOL isDirty;
@property(nonatomic, assign) BOOL contentsUpdating;
@property(nonatomic, strong) UIImage* currentBackgroundImage;
@end

/**
 *  This background drawing LynxBackgroundDrawables to the frame.
 */

@implementation LynxBackgroundSubBackgroundLayer
static const int kFrameQueueCapacity = 5;
dispatch_block_t mDispatchTask = NULL;

+ (dispatch_queue_t)concurrentDispatchQueue {
  static dispatch_queue_t displayQueue = NULL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    displayQueue = dispatch_queue_create("com.bytedance.lynx.background.gifRenderQueue",
                                         DISPATCH_QUEUE_CONCURRENT);
    // we use the highpri queue to prioritize UI rendering over other async operations
    dispatch_set_target_queue(displayQueue,
                              dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
  });

  return displayQueue;
}

- (void)clearAnimatedImage {
  if (mDispatchTask) {
    self.isPreRendering = NO;
  }
  if (_frameQueue) {
    // remove all cached frames and ensure thread safty.
    dispatch_barrier_async([[self class] concurrentDispatchQueue], ^{
      [self->_frameQueue removeAllObjects];
    });
  }
}

- (void)autoAdjustInsetsForContents:(UIImage*)frame {
  _elapsedDuration = 0;
  _currentBackgroundImage = frame;
  [self setNeedsDisplay];
}

- (void)markDirtyWithSize:(CGSize)viewSize
                    radii:(LynxBorderRadii)cornerRadii
             borderInsets:(UIEdgeInsets)borderInsets
          backgroundColor:(UIColor*)backgroundColor
               drawToEdge:(BOOL)drawToEdge
                capInsets:(UIEdgeInsets)insets {
  _viewSize = viewSize;
  _cornerRadii = cornerRadii;
  _borderInsets = borderInsets;
  _layerBackgroundColor = backgroundColor;
  _drawToEdge = drawToEdge;
  _currentFrameIndex = 0;
  _capInsets = insets;
  [self stopAnimation];
  [self clearAnimatedImage];

  if (!_isDirty && !self.contentsUpdating) {
    //     First data update in the frame interval. Draw bitmap directly.
    self.contentsUpdating = YES;
    [self onContentsUpdate];
  } else {
    // Already have image to display for next v-sync, mark dirty.
    // Image will be drawn in next v-sync interval.
    _isDirty = YES;
    if (![self needsDisplay]) {
      [self setNeedsDisplay];
    }
  }
}

- (void)startAnimation {
  if (!_displayLink) {
    // The displayLink will retain the target object. Using weakProxy here to avoid the layer
    // retained by the displayLink. Using weakProxy can let the lifecircle of background layer
    // independent of the displayLink. The displayLink will be cancelled when background layer
    // dealloc.
    LynxWeakProxy* weakProxy = [LynxWeakProxy proxyWithTarget:self];
    _displayLink = [CADisplayLink displayLinkWithTarget:weakProxy selector:@selector(updateFrame:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  }

  [self clearAnimatedImage];

  _needCalculateInterval = false;

  // Fixed refresh rate 30Hz.
  NSInteger fps = MAX(_frameCount / _animatedImageDuration, 1);

  if (@available(iOS 10.0, *)) {
    if (_frameCount < _animatedImageDuration) {
      fps = 30;
      _needCalculateInterval = true;
      _singleFrameDuration = _animatedImageDuration / _frameCount;
      _elapsedDuration = _singleFrameDuration;
    }
    self.displayLink.preferredFramesPerSecond = MIN(30, fps);
  } else {
    // Fallback on earlier versions
    self.displayLink.frameInterval = MAX(2, 60 / fps);
  }

  // start animation
  if (self.displayLink.isPaused) {
    [_displayLink setPaused:NO];
  }
}

- (void)applyStaticBackground {
  __weak LynxBackgroundSubBackgroundLayer* weakSelf = self;

  // deep copy thread safe.
  NSArray* imageArrayInfo = [[NSArray alloc] initWithArray:self.imageArray];
  UIColor* backgroundColorCopy = [_layerBackgroundColor copy];

  lynx_async_get_background_image_block_t displayBlock = ^{
    __strong LynxBackgroundSubBackgroundLayer* strongSelf = weakSelf;
    if (strongSelf) {
      return LynxGetBackgroundImageWithClip(
          strongSelf->_viewSize, strongSelf->_cornerRadii, strongSelf->_borderInsets,
          [backgroundColorCopy CGColor], NO, imageArrayInfo, strongSelf -> _backgroundColorClip,
          strongSelf -> _paddingWidth);
    }
    return (UIImage*)nil;
  };

  lynx_async_display_completion_block_t completionBlock = ^(UIImage* frame) {
    __strong LynxBackgroundSubBackgroundLayer* strongSelf = weakSelf;
    if (strongSelf && strongSelf.type == LynxBgTypeComplex) {
      [strongSelf autoAdjustInsetsForContents:frame];
    }
  };

  LynxBackgroundManager* manager = self.delegate;
  if (manager) {
    [manager.ui displayComplexBackgroundAsynchronouslyWithDisplay:displayBlock
                                                       completion:completionBlock];
  }
}

/**
 * The background props is updated, and should draw new static or animated image.
 */
- (void)onContentsUpdate {
  if (!_frameQueue) {
    // Ensure will not expand opacity in other thread to make thread safty.
    _frameQueue = [[NSMutableArray alloc] initWithCapacity:2 * kFrameQueueCapacity];
  }

  if (_isAnimated) {
    [self startAnimation];
  } else {
    [self applyStaticBackground];
  }
}

/**
 * Pause the displayLink to stop the animated image.
 */

- (void)stopAnimation {
  if (self.displayLink && !self.displayLink.isPaused) {
    self.displayLink.paused = YES;
  }
}

/**
 * All frames can be cached, no need to redraw.
 */
- (BOOL)canCacheAllFrames {
  return self.frameCount <= kFrameQueueCapacity;
}

/**
 *  Apply the next frame to layer.contents, and cache next few frames to buffer if needed.
 */
- (void)updateFrame:(CADisplayLink*)sender {
  if (@available(iOS 10.0, *)) {
    // Manually control the frame duration, when target frame rate is less than 1.
    if (_needCalculateInterval && _elapsedDuration < _singleFrameDuration) {
      _elapsedDuration += sender.targetTimestamp - CACurrentMediaTime();
      return;
    }
  }

  if ([self canCacheAllFrames]) {
    if ([_frameQueue count] == 0 && !_isPreRendering) {
      [self enqueueFrames:[self frameCount]];
    }
    if (!_isPreRendering) {
      _currentFrameIndex = _currentFrameIndex % _frameCount;
      [self autoAdjustInsetsForContents:[_frameQueue objectAtIndex:_currentFrameIndex]];
      ++_currentFrameIndex;
    }
  } else {
    // Pop the next frame
    UIImage* currentFrame;
    @synchronized(_frameQueue) {
      if ([_frameQueue count] > 0) {
        currentFrame = [_frameQueue objectAtIndex:0];
        [_frameQueue removeObjectAtIndex:0];
      }
    }
    if (currentFrame) {
      [self autoAdjustInsetsForContents:currentFrame];
    }

    // Cache the next kFrameQueueCapacity frames.
    if (!_isPreRendering && [_frameQueue count] < kFrameQueueCapacity / 2) {
      [self enqueueFrames:kFrameQueueCapacity];
    }
  }
}

- (dispatch_block_t)createFrameCacheTask:(NSInteger)count {
  __weak LynxBackgroundSubBackgroundLayer* weakSelf = self;

  // Deep copy thread safe.
  NSArray* imageArrayInfo = [[NSArray alloc] initWithArray:self.imageArray];
  UIColor* backgroundColorCopy = [_layerBackgroundColor copy];

  return dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
    __strong LynxBackgroundSubBackgroundLayer* strongSelf = weakSelf;
    if (strongSelf) {
      // TODO: make this async and concurrent.
      // Working with LynxBackgroundImageDrawable, each LynxGetBackgroundImage call will return the
      // next frame.
      for (NSInteger i = 0; i < count; ++i) {
        @autoreleasepool {
          UIImage* frame = LynxGetBackgroundImageWithClip(
              strongSelf->_viewSize, strongSelf->_cornerRadii, strongSelf->_borderInsets,
              [backgroundColorCopy CGColor], NO, imageArrayInfo, strongSelf -> _backgroundColorClip,
              strongSelf -> _paddingWidth);
          if (frame) {
            // prevent add nil exception
            @synchronized(strongSelf->_frameQueue) {
              [strongSelf->_frameQueue addObject:frame];
            }
          }
        }
      }
      strongSelf->_isPreRendering = NO;
    }
  });
}

/**
 * Append next few frames asynchronously.
 */
- (void)enqueueFrames:(NSInteger)count {
  _isPreRendering = YES;
  mDispatchTask = [self createFrameCacheTask:count];
  dispatch_async([[self class] concurrentDispatchQueue], mDispatchTask);
}

/**
 * Set up animation related attributes from the target image.
 */
- (void)setAnimatedPropsWithImage:(UIImage*)image {
  if (image && image.images) {
    _isAnimated = YES;
    _frameCount = [image.images count];

    // If duration is 0 for an animated image, use default value.
    _animatedImageDuration = image.duration == 0 ? _frameCount / 60.0 : image.duration;
  } else {
    _isAnimated = NO;
    _frameCount = 1;
    _animatedImageDuration = 0;
  }
}

///**
// * Let the prop updating controlled by v-sync.
// * Multiple updates within 1 v-sync should only trigger once drawing.
// */

- (void)display {
  if (_isDirty) {
    // Data changes are not applied, should launch a new render task.
    _isDirty = NO;
    [self onContentsUpdate];
  } else {
    // No data change and rendering completed.
    self.contentsUpdating = NO;
  }
  if (self.currentBackgroundImage) {
    adjustInsets(self.currentBackgroundImage, self, _capInsets);
  }
}

- (void)dealloc {
  [_displayLink invalidate];
}

@end
