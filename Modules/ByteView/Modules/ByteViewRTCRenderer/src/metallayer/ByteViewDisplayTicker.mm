#import "ByteViewDisplayTicker.h"
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#include <objc/NSObjCRuntime.h>

#include <algorithm>
#include <cinttypes>
#include <functional>
#include <iostream>
#include <iterator>
#include <map>
#include <vector>
#include <mutex>

#if DEBUG
#define DEBUG_LOG(msg)                                                         \
    std::cerr << "[ByteViewRender]" << __FUNCTION__ << "(" << __LINE__              \
              << "):" << msg << std::endl;
#else
#define DEBUG_LOG(msg)
#endif

@interface ByteViewRenderTicker ()

@end

@implementation ByteViewRenderTicker {
    std::vector<NSInteger> fpsList_;
    NSInteger maxFPS_;
    std::map<uint64_t, ByteViewMTLRenderCallback> mtl_render_callbacks_;
    std::map<uint64_t, NSInteger> preferred_fps_;
    std::mutex mutex_;
    CADisplayLink *displayLink_;
    id<MTLCommandQueue> commandQueue_;
    dispatch_queue_t renderQueue_;
}

- (instancetype)initWithFPSList:(const NSInteger *)fpsList fpsCount:(NSInteger)fpsCount maxFPS:(NSInteger)maxFPS {
    if (self = [super init]) {
        fpsList_ = std::vector<NSInteger>(fpsList, fpsList + fpsCount);
        maxFPS_ = maxFPS;
        _device = MTLCreateSystemDefaultDevice();
        commandQueue_ = [self.device newCommandQueue];
        displayLink_ = [CADisplayLink displayLinkWithTarget:self
                                                   selector:@selector(step)];
        displayLink_.preferredFramesPerSecond = maxFPS;
        displayLink_.paused = YES;
        self->renderQueue_ =
            dispatch_queue_create("vc.render", DISPATCH_QUEUE_SERIAL);

        [displayLink_ addToRunLoop:NSRunLoop.currentRunLoop
                           forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)updateFPSList:(const NSInteger *)fpsList fpsCount:(NSInteger)fpsCount maxFPS:(NSInteger)maxFPS {
    std::lock_guard<decltype(mutex_)> lock(mutex_);
    std::vector<NSInteger> newFPSList(fpsList, fpsList + fpsCount);
    if (fpsList_ == newFPSList && maxFPS_ == maxFPS) return;
    fpsList_ = newFPSList;
    maxFPS_ = maxFPS;
    [self updateDisplayLinkFPS];
}

- (void)updateDisplayLinkFPS {
    if (preferred_fps_.empty())
        return;
    const auto min_max_fps = std::minmax_element(
        preferred_fps_.begin(), preferred_fps_.end(),
        [](const std::pair<uint64_t, NSInteger> &lhs,
           const std::pair<uint64_t, NSInteger> &rhs) -> bool {
            return lhs.second < rhs.second;
        });
    auto min_fps = min_max_fps.first->second;
    auto fps = min_max_fps.second->second;

    auto beg = std::begin(fpsList_);
    auto end = std::end(fpsList_);
    auto itr = std::lower_bound(beg, end, fps);
    NSInteger selected_fps = maxFPS_;
    if (itr == end) {
        selected_fps = maxFPS_;
    } else {
        selected_fps = *itr;
    }
    if (selected_fps != displayLink_.preferredFramesPerSecond) {
        displayLink_.preferredFramesPerSecond = selected_fps;
        DEBUG_LOG("updatePreferredFPS: " << selected_fps << ", min: " << min_fps
                                         << ", max: " << fps);
    }
}

- (void)renderer:(uint64_t)renderID updatePreferredFPS:(NSInteger)fps {
    std::lock_guard<decltype(mutex_)> lock(mutex_);
    if (mtl_render_callbacks_.find(renderID) == mtl_render_callbacks_.end())
        return;
    if (preferred_fps_[renderID] == fps)
        return;
    preferred_fps_[renderID] = fps;
    [self updateDisplayLinkFPS];
}

- (BOOL)registerMTLRenderCallbackWithID:(uint64_t)callbackID
                                fpsHint:(NSInteger)fps
                               callback:(ByteViewMTLRenderCallback)callback {
    DEBUG_LOG("fpsHint: " << fps);
    std::lock_guard<decltype(mutex_)> lock(mutex_);
    if (mtl_render_callbacks_.find(callbackID) != mtl_render_callbacks_.end())
        return false;
    bool startDisplaylink = mtl_render_callbacks_.empty();

    self->mtl_render_callbacks_.insert({callbackID, callback});
    if (startDisplaylink) {
        self->displayLink_.paused = NO;
    }
    if (fps > 0) {
        preferred_fps_[callbackID] = fps;
        [self updateDisplayLinkFPS];
    }
    return true;
}

- (BOOL)unregisterCallbackWithID:(uint64_t)callbackID {
    std::lock_guard<decltype(mutex_)> lock(mutex_);
    auto isremoved = self->mtl_render_callbacks_.erase(callbackID) > 0;
    if (mtl_render_callbacks_.empty()) {
        self->displayLink_.paused = YES;
    }
    if (preferred_fps_.erase(callbackID) > 0)
        [self updateDisplayLinkFPS];
    DEBUG_LOG("remains renderer count " << self->mtl_render_callbacks_.size());
    return isremoved;
}

- (void)step {
    if (!self.dirty) {
        return;
    }
    self.dirty = NO;
    std::map<uint64_t, ByteViewMTLRenderCallback> tmp_callbacks;
    {
        std::lock_guard<decltype(mutex_)> lock(mutex_);
        if (self->mtl_render_callbacks_.empty()) {
            return;
        }
        tmp_callbacks = self->mtl_render_callbacks_;
    }
    auto buffer = [self->commandQueue_ commandBuffer];
    dispatch_async(self->renderQueue_, ^{
        bool needsCommit = false;
        for (auto &kv : tmp_callbacks) {
            if (kv.second(buffer)) {
                needsCommit = true;
            }
        }
        if (needsCommit) {
            [buffer commit];
        }
    });
}

-(void)dealloc {
    DEBUG_LOG("destroy ticker");
}

@end
