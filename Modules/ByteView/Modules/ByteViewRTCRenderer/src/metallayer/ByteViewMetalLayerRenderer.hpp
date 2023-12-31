//
//  ByteViewMetalLayerRenderer.h
//  ByteViewRTCRenderer
//
//  Created by liujianlong on 2022/7/28.
//

#ifndef ByteViewMetalLayerRenderer_h
#define ByteViewMetalLayerRenderer_h

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#include <CoreVideo/CoreVideo.h>
#include "ByteViewMTLLayerRenderer.hpp"
#include <dispatch/dispatch.h>
#include <memory>
#include <functional>
#include <mutex>

namespace byteview {

class MetalLayerRenderer: public PixelBufferRenderer, public std::enable_shared_from_this<MetalLayerRenderer> {
public:
    MetalLayerRenderer();
    ~MetalLayerRenderer();
    MetalLayerRenderer(const MetalLayerRenderer&) = delete;
    MetalLayerRenderer& operator = (const MetalLayerRenderer&) = delete;
    bool init(id<MTLDevice> device, CAMetalLayer *layer, NSLock *layerLock, bool use_shared_displaylink);
    virtual void renderPixelBuffer(PixelBufferWrapper buffer, CompletionCallback completion) override;

    bool tickRender(id<MTLCommandBuffer> commandBuffer);

private:
    void render(PixelBufferWrapper buffer, CAMetalLayer *layer, CompletionCallback completion);
    bool render(id<MTLCommandBuffer> commandBuffer, PixelBufferWrapper buffer, CAMetalLayer *layer, CompletionCallback completion);
    void render_pending_frame();
    void updatePixelBuffer(PixelBufferWrapper buffer, CompletionCallback completion);

    id<MTLRenderPipelineState> getOrCreateRGBPipelineState();
    id<MTLBuffer> getOrCreateVertexBuffer(const PixelBufferWrapper& pixelBuffer);

    id<MTLTexture> createTexture(CVPixelBufferRef pixelBuffer, MTLPixelFormat pixelFormat);

    id<MTLTexture> createTexture(CVPixelBufferRef pixelBuffer, MTLPixelFormat pixelFormat, int planeIndex);

private:
    id<MTLDevice> device_;
    // 默认渲染模式，收到视频数据后立即绘制
    bool use_shared_displaylink_ = false;
    NSLock *layer_lock_;
    CAMetalLayer *layer_;
    CVMetalTextureCacheRef texture_cache_;
    id<MTLCommandQueue> command_queue_;
    id<MTLRenderPipelineState> ycbcr_pipeline_state_;
    id<MTLRenderPipelineState> rgb_pipeline_state_;
    MTLRenderPassDescriptor *render_pass_desc_;
    MTLPixelFormat pixel_format_;
    id<MTLBuffer> bt601_fullrange_conversion_matrix_;
    id<MTLBuffer> bt601_videorange_conversion_matrix_;
    id<MTLBuffer> bt709_fullrange_conversion_matrix_;
    id<MTLBuffer> bt709_videorange_conversion_matrix_;
    id<MTLBuffer> bt2020_fullrange_conversion_matrix_;
    id<MTLBuffer> bt2020_videorange_conversion_matrix_;

    id<MTLBuffer> last_vertex_buffer_;
    float last_crop_x_;
    float last_crop_y_;
    float last_crop_width_;
    float last_crop_height_;
    PixelBufferWrapper::Rotation last_rotation_;
    bool last_flip_;

    std::mutex mutex_;
    bool is_drawing_;
    int frame_dropped_;
    PixelBufferWrapper pending_buffer_;
    CompletionCallback pending_comp_;

#ifdef DEBUG
    bool first_drawable_logged_ = false;
#endif

};

}


#endif /* ByteViewMetalLayerRenderer_h */
