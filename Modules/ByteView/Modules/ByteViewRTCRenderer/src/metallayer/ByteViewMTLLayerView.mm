//
//  ByteViewMTLLayerView.m
//  ByteViewRTCRenderer
//
//  Created by liujianlong on 2022/7/28.
//

#import "ByteViewMTLLayerView.h"
#import "ByteViewDisplayTicker.h"
#import "ByteViewRenderView+Initialize.h"
#import "ByteViewMetalLayerRenderer.hpp"
#import <chrono>
#import <iostream>

using namespace byteview;

@class ByteViewMTLLayerFrameReceiver;

@interface ByteViewMTLLayerView ()

@property(strong, nonatomic) ByteViewMTLLayerFrameReceiver *frameReceiverImpl;

- (void)setVideoFrameSize:(CGSize)size;

@end

@interface ByteViewMTLLayerFrameReceiver : NSObject <ByteViewVideoRenderer>

@property(weak, nonatomic) ByteViewMTLLayerView *parent;
@property(assign, nonatomic) std::shared_ptr<MetalLayerRenderer> renderer;

@property(assign, atomic) CGSize lastFrameSize;

@property(assign, atomic) std::chrono::steady_clock::time_point lastRecordTime;
@property(assign, atomic) NSUInteger frameCount;

@property(weak, nonatomic) ByteViewRenderTicker *ticker;

@end

@implementation ByteViewMTLLayerFrameReceiver

- (instancetype)init {
    if (self = [super init]) {
        self.lastRecordTime = std::chrono::steady_clock::now();
        self.frameCount = 0;
    }
    return self;
}

- (void)renderFrame:(nullable ByteViewVideoFrame *)videoFrame {
    using namespace byteview;
    if (!videoFrame)
        return;
    CGSize frameSize = videoFrame.size;
    if (!CGSizeEqualToSize(frameSize, self.lastFrameSize)) {
        self.lastFrameSize = frameSize;
        if (NSThread.isMainThread) {
            [self.parent setVideoFrameSize:frameSize];
            [self.parent layoutIfNeeded];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.parent setVideoFrameSize:frameSize];
            });
        }
    }
    auto ticker = self.ticker;
    if (ticker) {
        self.frameCount += 1;
        auto now = std::chrono::steady_clock::now();
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            now - self.lastRecordTime);
        if (ms.count() >= 1000) {
            auto fps = self.frameCount / (ms.count() / 1000.0);
            self.lastRecordTime = now;
            self.frameCount = 0;
            [ticker renderer:(uint64_t)(__bridge void *)self
                updatePreferredFPS:fps];
        }
    }

    auto pixelBuffer = videoFrame.pixelBuffer;
    PixelBufferWrapper pixelBufferWrapper;
    CVPixelBufferRetain(pixelBuffer);
    pixelBufferWrapper.buffer.reset(pixelBuffer);
    auto rotation = PixelBufferWrapper::Rotation_0;
    switch (videoFrame.rotation) {
        case ByteViewVideoRotation_0:
            rotation = byteview::PixelBufferWrapper::Rotation_0;
            break;
        case ByteViewVideoRotation_90:
            rotation = byteview::PixelBufferWrapper::Rotation_90;
            break;
        case ByteViewVideoRotation_180:
            rotation = byteview::PixelBufferWrapper::Rotation_180;
            break;
        case ByteViewVideoRotation_270:
            rotation = byteview::PixelBufferWrapper::Rotation_270;
            break;
        default:
            rotation = byteview::PixelBufferWrapper::Rotation_0;
            break;
    }

    if (videoFrame.flip) {
        if (videoFrame.flipHorizontal) {
            switch (rotation) {
                case byteview::PixelBufferWrapper::Rotation_0:
                    rotation = byteview::PixelBufferWrapper::Rotation_0;
                    break;
                case byteview::PixelBufferWrapper::Rotation_90:
                    rotation = byteview::PixelBufferWrapper::Rotation_270;
                    break;
                case byteview::PixelBufferWrapper::Rotation_180:
                    rotation = byteview::PixelBufferWrapper::Rotation_180;
                    break;
                case byteview::PixelBufferWrapper::Rotation_270:
                    rotation = byteview::PixelBufferWrapper::Rotation_90;
                    break;
            }
        } else {
            switch (rotation) {
                case byteview::PixelBufferWrapper::Rotation_0:
                    rotation = byteview::PixelBufferWrapper::Rotation_180;
                    break;
                case byteview::PixelBufferWrapper::Rotation_90:
                    rotation = byteview::PixelBufferWrapper::Rotation_90;
                    break;
                case byteview::PixelBufferWrapper::Rotation_180:
                    rotation = byteview::PixelBufferWrapper::Rotation_0;
                    break;
                case byteview::PixelBufferWrapper::Rotation_270:
                    rotation = byteview::PixelBufferWrapper::Rotation_270;
                    break;
            }
        }
    }
    pixelBufferWrapper.crop_x = videoFrame.cropRect.origin.x;
    pixelBufferWrapper.crop_y = videoFrame.cropRect.origin.y;
    pixelBufferWrapper.crop_width = videoFrame.cropRect.size.width;
    pixelBufferWrapper.crop_height = videoFrame.cropRect.size.height;
    pixelBufferWrapper.horizontal_flip = videoFrame.flip;
    pixelBufferWrapper.rotation = rotation;

    /*
    if (isFrontCamera && mirror)
    switch (UIApplication.sharedApplication.statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
            rotation = PixelBufferWrapper::Rotation_270;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            rotation = PixelBufferWrapper::Rotation_90;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rotation = PixelBufferWrapper::Rotation_0;
            break;
        case UIInterfaceOrientationLandscapeRight:
            rotation = PixelBufferWrapper::Rotation_180;
            break;
    }
    else
    switch (UIApplication.sharedApplication.statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
            rotation = PixelBufferWrapper::Rotation_90;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            rotation = PixelBufferWrapper::Rotation_270;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rotation = PixelBufferWrapper::Rotation_180;
            break;
        case UIInterfaceOrientationLandscapeRight:
            rotation = PixelBufferWrapper::Rotation_0;
            break;
    }
     */

    __weak __typeof(self) wself = self;
    auto start = std::chrono::steady_clock::now();
    self.renderer->renderPixelBuffer(
        std::move(pixelBufferWrapper), [wself, start](bool success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ByteViewMTLLayerView *layerView = wself.parent;
                if (success && layerView) {
                    auto elapse = std::chrono::steady_clock::now() - start;
                    auto elapseMS =
                        std::chrono::duration_cast<std::chrono::milliseconds>(
                            elapse);
                    [layerView.renderElapseObserver reportRenderElapse:(int)elapseMS.count()];
                }
            });
        });
    self.ticker.dirty = YES;
}

@end

@implementation ByteViewMTLLayerView {
    std::shared_ptr<MetalLayerRenderer> _renderer;
    ByteViewRenderTicker *_ticker;
    CAMetalLayer *_metalLayer;
    NSLock *_layerLock;
    CGSize _frameSize;
}

- (instancetype)initWithRenderTicker:(ByteViewRenderTicker *)renderTicker
                             fpsHint:(NSInteger)fps {
    if (self = [super _initWithFrame:CGRectZero]) {
        _ticker = renderTicker;
        [self setupWithTicker:renderTicker fpsHint:fps];
    }
    return self;
}

- (void)setVideoFrameSize:(CGSize)size {
    if (CGSizeEqualToSize(_frameSize, size)) {
        return;
    }
    _frameSize = size;
    [self setNeedsLayout];
}

- (void)setupWithTicker:(ByteViewRenderTicker *)ticker fpsHint:(NSInteger)fps {
    auto device = ticker != nil
                      ? ticker.device
                      : MTLCreateSystemDefaultDevice();
    if (!device)
        return;
    CAMetalLayer *layer = [CAMetalLayer layer];
    layer.framebufferOnly = YES;
    [layer setDevice:device];
    _renderer = std::make_shared<MetalLayerRenderer>();
    _metalLayer = layer;
    _layerLock = [[NSLock alloc] init];
    if (!_renderer->init(device, layer, _layerLock, ticker != nil))
        return;
    [self.layer addSublayer:_metalLayer];
    ByteViewMTLLayerFrameReceiver *receiver =
        [[ByteViewMTLLayerFrameReceiver alloc] init];
    receiver.parent = self;
    receiver.renderer = _renderer;
    self.frameReceiver = receiver;
    self.frameReceiverImpl = receiver;

    if (_ticker != nil) {
        receiver.ticker = _ticker;
        __weak __typeof(self.frameReceiverImpl) w_receiver = self.frameReceiverImpl;
        [_ticker
            registerMTLRenderCallbackWithID:(uint64_t)(__bridge void *)receiver
                                    fpsHint:fps
                                   callback:^(id<MTLCommandBuffer> buffer) {
                                       auto s_receiver = w_receiver;
                                       if (s_receiver == nil)
                                           return false;
                                       return s_receiver.renderer->tickRender(buffer);
                                   }];
    }
}

- (void)dealloc {
    if (_ticker != nil) {
        [_ticker unregisterCallbackWithID:(uint64_t)(__bridge void *)_frameReceiverImpl];
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    //    _metalLayer.contentsScale = self.contentScaleFactor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [_layerLock lock];
    //    _metalLayer.contentsScale = self.contentScaleFactor;
    CAAnimation *animation = [self.layer animationForKey:@"bounds.size"];
    if (animation) {
        [CATransaction begin];
        [CATransaction setAnimationDuration:animation.duration];
        [CATransaction setAnimationTimingFunction:animation.timingFunction];
        _metalLayer.frame = self.bounds;
        [CATransaction commit];
    } else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        _metalLayer.frame = self.bounds;
        [CATransaction commit];
    }
    [self updateDrawableSize];
    [_layerLock unlock];
}

- (CGSize)computeDrawableSize {
    CGFloat scale = self.window.screen != nil ? self.window.screen.scale
                                              : UIScreen.mainScreen.scale;
    CGSize boundsDrawableSize = CGSizeMake(self.bounds.size.width * scale,
                                           self.bounds.size.height * scale);
    CGSize videoFrameDrawableSize = _frameSize;
    if (videoFrameDrawableSize.width < 1 || videoFrameDrawableSize.height < 1) {
        return CGSizeMake(1.0f, 1.0f);
    }
    if (boundsDrawableSize.width < 1 || boundsDrawableSize.height < 1) {
        return CGSizeMake(1.0f, 1.0f);
    }
    if (videoFrameDrawableSize.width * videoFrameDrawableSize.height >
        boundsDrawableSize.width * boundsDrawableSize.height) {
        return boundsDrawableSize;
    } else {
        return videoFrameDrawableSize;
    }
}

- (void)updateDrawableSize {
    CGSize drawableSize = [self computeDrawableSize];
    _metalLayer.drawableSize = drawableSize;
}

@end
