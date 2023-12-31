#include "ByteViewMetalLayerRenderer.hpp"
#import "ByteViewRTCLogging.h"
#include "byteview_mtl_common.hpp"
#include <cassert>
#include <iostream>
#include <mutex>
#include <simd/simd.h>
#include <chrono>

namespace {
using namespace byteview;
id<MTLBuffer> UploadColorConversionMatrix(const ColorConversionParams &data, id<MTLDevice> device, id<MTLCommandBuffer> cmdBuffer, id<MTLBuffer> __strong *buffer) {
    if (*buffer) return *buffer;
    *buffer = [device newBufferWithBytes:(void *)&data
                                  length:sizeof(ColorConversionParams)
                                 options:MTLResourceStorageModeShared];

    id<MTLBuffer> privateBuffer = [device newBufferWithLength:sizeof(ColorConversionParams)
                                                      options:MTLResourceStorageModePrivate];
    id<MTLBlitCommandEncoder> encoder = [cmdBuffer blitCommandEncoder];
    [encoder copyFromBuffer:*buffer
               sourceOffset:0
                   toBuffer:privateBuffer
          destinationOffset:0
                       size:sizeof(ColorConversionParams)];
    [encoder endEncoding];
    *buffer = privateBuffer;
    return *buffer;
}

enum VertexIndex : int {
    bottomLeft = 0,
    bottomRight,
    topRight,
    topLeft,
};

constexpr simd::float2 quad_verts[4] = {
    {-1.0, -1.0},
    {1.0, -1.0},
    {1.0, 1.0},
    {-1.0, 1.0},
};

id<MTLBuffer> CreateVertexBufferForFrame(const PixelBufferWrapper &frame, id<MTLDevice> device) {
    auto rotation = frame.rotation;
#if DEBUG
    std::cerr << "RTCRender.Log: create vertex buffer, "
            << "x: " << frame.crop_x
            << ", y: " << frame.crop_y
            << ", w: " << frame.crop_width
            << ", h: " << frame.crop_height
            << ", f: " << frame.horizontal_flip
            << ", r: " << frame.rotation
              << std::endl;
#endif
    simd::float2 tex_coords[] = {
        {frame.crop_x, frame.crop_y + frame.crop_height},
        {frame.crop_x + frame.crop_width, frame.crop_y + frame.crop_height},
        {frame.crop_x + frame.crop_width, frame.crop_y},
        {frame.crop_x, frame.crop_y},
    };

    simd::float2 flipped_tex_coords[] = {
        {frame.crop_x + frame.crop_width, frame.crop_y + frame.crop_height},
        {frame.crop_x, frame.crop_y + frame.crop_height},
        {frame.crop_x, frame.crop_y},
        {frame.crop_x + frame.crop_width, frame.crop_y},
    };

    auto texcoords = frame.horizontal_flip ? flipped_tex_coords : tex_coords;

    InputVertex data[4] = {
        // bottom left
            { .coord = quad_verts[bottomLeft], .tex_coord = texcoords[(bottomLeft + rotation) % 4], },
        // bottom right
            { .coord = quad_verts[bottomRight], .tex_coord = texcoords[(bottomRight + rotation) % 4], },
        // top left
            { .coord = quad_verts[topLeft], .tex_coord = texcoords[(topLeft + rotation) % 4], },
        // top right
            { .coord = quad_verts[topRight], .tex_coord = texcoords[(topRight + rotation) % 4], },
    };
    return [device newBufferWithBytes:data length:sizeof(data) options:MTLResourceStorageModeShared];
}

}

namespace byteview {

const ColorConversionParams BT601FullRange = {
    .matrix = {
        simd::float3{ 1.000,  1.000, 1.000,},
        simd::float3{ 0.000, -0.343, 1.765,},
        simd::float3{ 1.400, -0.711, 0.000,},
        },
    .offset = {0.0, -0.5, -0.5},
};

const ColorConversionParams BT601VideoRange = {
    .matrix = {
        simd::float3{ 1.164,  1.164, 1.164,},
        simd::float3{ 0.000, -0.392, 2.017,},
        simd::float3{ 1.596, -0.813, 0.000,},
        },
    .offset = {(-16.0 / 255.0), -0.5, -0.5},
};

const ColorConversionParams BT709FullRange = {
    .matrix = {
        simd::float3{ 1.000,  1.000, 1.000,},
        simd::float3{ 0.000, -0.187, 1.856,},
        simd::float3{ 1.575, -0.468, 0.000,},
        },
    .offset = {0.0, -0.5, -0.5},
};

const ColorConversionParams BT709VideoRange = {
    .matrix = {
        simd::float3{ 1.164,  1.164, 1.164,},
        simd::float3{ 0.000, -0.213, 2.112,},
        simd::float3{ 1.793, -0.533, 0.000,},
        },
    .offset = {(-16.0 / 255.0), -0.5, -0.5},
};


const ColorConversionParams BT2020FullRange = {
    .matrix = {
        simd::float3{ 1.000,  1.000, 1.000,},
        simd::float3{ 0.000, -0.165, 1.881,},
        simd::float3{ 1.475, -0.571, 0.000,},
        },
    .offset = {0.0, -0.5, -0.5},
};

const ColorConversionParams BT2020VideoRange = {
    .matrix = {
        simd::float3{ 1.164,  1.164, 1.164,},
        simd::float3{ 0.000, -0.187, 2.142,},
        simd::float3{ 1.679, -0.650, 0.000,},
        },
    .offset = {(-16.0 / 255.0), -0.5, -0.5},
};

MetalLayerRenderer::MetalLayerRenderer() : texture_cache_(nullptr), is_drawing_(false), frame_dropped_(0) {}

MetalLayerRenderer::~MetalLayerRenderer() {
    if (texture_cache_) {
        CFRelease(texture_cache_);
    }
}
id<MTLTexture> MetalLayerRenderer::createTexture(CVPixelBufferRef pixelBuffer, MTLPixelFormat pixelFormat) {
    if (!texture_cache_) { return nil; }
    CVMetalTextureRef texture = NULL;
    auto width = CVPixelBufferGetWidth(pixelBuffer);
    auto height = CVPixelBufferGetHeight(pixelBuffer);
    auto rc = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, texture_cache_, pixelBuffer, NULL, pixelFormat, width, height, 0, &texture);
    if (rc != kCVReturnSuccess) return nil;
    auto ret = CVMetalTextureGetTexture(texture);
    CVBufferRelease(texture);
    return ret;
}

id<MTLTexture> MetalLayerRenderer::createTexture(CVPixelBufferRef pixelBuffer, MTLPixelFormat pixelFormat, int planeIndex) {
    if (!texture_cache_) { return nil; }
    CVMetalTextureRef texture = NULL;
    auto width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
    auto height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);
    auto rc = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, texture_cache_, pixelBuffer, NULL, pixelFormat, width, height, planeIndex, &texture);
    if (rc != kCVReturnSuccess) return nil;
    auto ret = CVMetalTextureGetTexture(texture);
    CVBufferRelease(texture);
    return ret;
}

id<MTLRenderPipelineState> MetalLayerRenderer::getOrCreateRGBPipelineState() {
    if (rgb_pipeline_state_) return rgb_pipeline_state_;
    if (!device_) return nil;

#if SWIFT_PACKAGE
    NSBundle *bundle = SWIFTPM_MODULE_BUNDLE;
#else
    NSURL *bundleURL = [NSBundle.mainBundle URLForResource:@"byteview_renderer" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
#endif

    NSError *error;
    auto library = [device_ newDefaultLibraryWithBundle:bundle error:&error];
    if (!library) {
        return nil;
    }

    auto vertex_shader = [library newFunctionWithName:@"byteview_vertex_shader"];
    auto rgb_fragment_shader = [library newFunctionWithName:@"byteview_rgb_fragment_shader"];
    if (!vertex_shader || !rgb_fragment_shader) return nil;

    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.label = @"byteview-renderer-rgb";
    pipelineDescriptor.vertexFunction = vertex_shader;
    pipelineDescriptor.fragmentFunction = rgb_fragment_shader;
    pipelineDescriptor.colorAttachments[0].pixelFormat = pixel_format_;

    rgb_pipeline_state_ = [device_ newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    return rgb_pipeline_state_;
}

id<MTLBuffer> MetalLayerRenderer::getOrCreateVertexBuffer(const PixelBufferWrapper &buffer) {

    if (last_vertex_buffer_ != nil && buffer.rotation == last_rotation_ && buffer.crop_x == last_crop_x_ &&
      buffer.crop_y == last_crop_y_ && buffer.crop_width == last_crop_width_ && buffer.crop_height == last_crop_height_ &&
      buffer.horizontal_flip == last_flip_) {
        // reuse last vertex buffer
    } else {
        last_rotation_ = buffer.rotation;
        last_flip_ = buffer.horizontal_flip;
        last_crop_x_ = buffer.crop_x;
        last_crop_y_ = buffer.crop_y;
        last_crop_width_ = buffer.crop_width;
        last_crop_height_ = buffer.crop_height;
        last_vertex_buffer_ = CreateVertexBufferForFrame(buffer, device_);
    }
    return last_vertex_buffer_;
}

bool MetalLayerRenderer::init(id<MTLDevice> device, CAMetalLayer *layer, NSLock *layerLock, bool use_shared_displaylink) {
    device_ = device;
    layer_ = layer;
    layer_lock_ = layerLock;
    pixel_format_ = layer.pixelFormat;
    use_shared_displaylink_ = use_shared_displaylink;

#if SWIFT_PACKAGE
    NSBundle *bundle = SWIFTPM_MODULE_BUNDLE;
#else
    NSURL *bundleURL = [NSBundle.mainBundle URLForResource:@"byteview_renderer" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
#endif
    if (!bundle) {
        ByteViewRTCLogError(@"failed loading metal bundle");
        return false;
    }

    NSError *error;
    auto library = [device newDefaultLibraryWithBundle:bundle error:&error];
    if (!library) {
        ByteViewRTCLogError(@"failed loading metal library");
        return false;
    }

    auto vertex_shader = [library newFunctionWithName:@"byteview_vertex_shader"];
    auto fragment_shader = [library newFunctionWithName:@"byteview_fragment_shader"];

    if (vertex_shader == nil || fragment_shader == nil) {
        ByteViewRTCLogError(@"failed loading metal shader, functions: %@", library.functionNames);
        return false;
    }

    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.label = @"byteview-renderer";
    pipelineDescriptor.vertexFunction = vertex_shader;
    pipelineDescriptor.fragmentFunction = fragment_shader;
    pipelineDescriptor.colorAttachments[0].pixelFormat = pixel_format_;

    ycbcr_pipeline_state_ = [device_ newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!ycbcr_pipeline_state_) {
        ByteViewRTCLogError(@"failed create pipelinestate %@", error.localizedDescription);
        return false;
    }

    render_pass_desc_ = [MTLRenderPassDescriptor renderPassDescriptor];
    render_pass_desc_.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    render_pass_desc_.colorAttachments[0].storeAction = MTLStoreActionStore;

    if (!use_shared_displaylink) {
        command_queue_ = [device_ newCommandQueue];
    }

    auto rc = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, device, NULL, &texture_cache_);
    if (rc != kCVReturnSuccess) {
        ByteViewRTCLogError(@"failed creating texturecache");
        return false;
    }
    return true;
}

void MetalLayerRenderer::renderPixelBuffer(PixelBufferWrapper buffer, CompletionCallback comp) {
    if (use_shared_displaylink_) {
        updatePixelBuffer(std::move(buffer), std::move(comp));
        return;
    }
    {
        std::lock_guard<decltype(mutex_)> lock(mutex_);
        if (is_drawing_) {
            if (this->pending_buffer_.buffer) {
                ++frame_dropped_;
                if ((frame_dropped_ - 1) % 15 == 0) {
                    ByteViewRTCLogError(@"frame dropped %d", frame_dropped_);
                }
                if (this->pending_comp_) {
                    this->pending_comp_(false);
                    this->pending_comp_ = nullptr;
                }
            }
            this->pending_buffer_ = std::move(buffer);
            this->pending_comp_ = std::move(comp);
            return;
        } else {
            assert(!this->pending_buffer_.buffer);
        }
        is_drawing_ = true;
    }
    auto selfptr = shared_from_this();
    auto completion = [selfptr, comp](bool success) {
        comp(success);
        selfptr->render_pending_frame();
    };
    @autoreleasepool {
        render(std::move(buffer), layer_, std::move(completion));
    }
    return;
}

void MetalLayerRenderer::render_pending_frame() {
    mutex_.lock();
    if (pending_buffer_.buffer) {
        auto comp = std::move(this->pending_comp_);
        auto buffer = std::move(pending_buffer_);
        mutex_.unlock();
        auto selfptr = shared_from_this();
        auto completion = [selfptr, comp](bool success) {
            comp(success);
            selfptr->render_pending_frame();
        };
        @autoreleasepool {
            render(std::move(buffer), layer_, std::move(completion));
        }
    } else {
        is_drawing_ = false;
        mutex_.unlock();
    }
}

void MetalLayerRenderer::render(PixelBufferWrapper buffer, CAMetalLayer *layer,
                                CompletionCallback completion) {
    auto commandBuffer = [command_queue_ commandBuffer];
    auto shouldCommit =
        render(commandBuffer, std::move(buffer), layer, std::move(completion));
    if (shouldCommit) {
        [commandBuffer commit];
    }
    return;
}

bool MetalLayerRenderer::render(id<MTLCommandBuffer> commandBuffer, PixelBufferWrapper buffer, CAMetalLayer *layer,
                                CompletionCallback completion) {
    if (!commandBuffer) {
        if (completion)
            completion(false);
        return false;
    }

    auto pixelBuffer = buffer.buffer.get();
    if (!pixelBuffer || !layer) {
        if (completion)
            completion(false);
        return false;
    }
    [layer_lock_ lock];
    auto drawable = [layer nextDrawable];
    [layer_lock_ unlock];
    if (!drawable) {
        if (completion)
            completion(false);
        return false;
    }

#ifdef DEBUG
    if (!first_drawable_logged_) {
        first_drawable_logged_ = true;
        std::cerr << "RTCRender.Log: first drawable size: " << drawable.texture.width << ", " << drawable.texture.height
                  << std::endl;
    }
#endif
    auto format = CVPixelBufferGetPixelFormatType(pixelBuffer);
    id<MTLBuffer> matrix = nil;
    bool isRGB = false;
    switch (format) {
    case kCVPixelFormatType_32BGRA:
    case kCVPixelFormatType_32ARGB: {
        isRGB = true;
        break;
    }
    case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
#pragma clang diagnostic pop
        if (colorAttachments) {
            if (CFStringCompare((CFStringRef)colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4,
                                kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                matrix = UploadColorConversionMatrix(BT601FullRange, device_, commandBuffer,
                                                     &bt601_fullrange_conversion_matrix_);
            } else if (CFStringCompare((CFStringRef)colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_709_2,
                                       kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                matrix = UploadColorConversionMatrix(BT709FullRange, device_, commandBuffer,
                                                     &bt709_fullrange_conversion_matrix_);
            } else if (CFStringCompare((CFStringRef)colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_2020,
                                       kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                matrix = UploadColorConversionMatrix(BT2020FullRange, device_, commandBuffer,
                                                     &bt2020_fullrange_conversion_matrix_);
            } else {
                matrix = UploadColorConversionMatrix(BT601FullRange, device_, commandBuffer,
                                                     &bt601_fullrange_conversion_matrix_);
            }
        } else {
            matrix = UploadColorConversionMatrix(BT709FullRange, device_, commandBuffer,
                                                 &bt709_fullrange_conversion_matrix_);
        }
        break;
    }
    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
#pragma clang diagnostic pop
        if (colorAttachments) {
            if (CFStringCompare((CFStringRef)colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4,
                                kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                matrix = UploadColorConversionMatrix(BT601VideoRange, device_, commandBuffer,
                                                     &bt601_videorange_conversion_matrix_);
            } else if (CFStringCompare((CFStringRef)colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_709_2,
                                       kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                matrix = UploadColorConversionMatrix(BT709VideoRange, device_, commandBuffer,
                                                     &bt709_videorange_conversion_matrix_);
            } else if (CFStringCompare((CFStringRef)colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_2020,
                                       kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                matrix = UploadColorConversionMatrix(BT2020VideoRange, device_, commandBuffer,
                                                     &bt2020_videorange_conversion_matrix_);
            } else {
                matrix = UploadColorConversionMatrix(BT601VideoRange, device_, commandBuffer,
                                                     &bt601_videorange_conversion_matrix_);
            }
        } else {
            matrix = UploadColorConversionMatrix(BT709VideoRange, device_, commandBuffer,
                                                 &bt709_videorange_conversion_matrix_);
        }
        break;
    }
    default: {
        if (completion)
            completion(false);
        return false;
    }
    }

    id<MTLRenderPipelineState> pipelineState = nil;
    if (isRGB) {
        pipelineState = getOrCreateRGBPipelineState();
    } else {
        pipelineState = ycbcr_pipeline_state_;
    }
    if (!pipelineState) {
        if (completion)
            completion(false);
        return false;
    }

    render_pass_desc_.colorAttachments[0].texture = drawable.texture;
    auto renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:render_pass_desc_];
    [renderEncoder setRenderPipelineState:pipelineState];

    auto vertexBuffer = getOrCreateVertexBuffer(buffer);
    [renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];

    if (isRGB) {
        id<MTLTexture> texture;
        bool isARGB = false;
        if (format == kCVPixelFormatType_32BGRA) {
            texture = createTexture(pixelBuffer, MTLPixelFormatBGRA8Unorm);
        } else {
            isARGB = true;
            texture = createTexture(pixelBuffer, MTLPixelFormatRGBA8Unorm);
        }
        if (!texture) {
            if (completion)
                completion(false);
            return false;
        }
        id<MTLBuffer> isARGBUniform = [device_ newBufferWithBytes:&isARGB
                                                           length:sizeof(isRGB)
                                                          options:MTLResourceStorageModeShared];
        [renderEncoder setFragmentTexture:texture atIndex:0];
        [renderEncoder setFragmentBuffer:isARGBUniform offset:0 atIndex:0];
    } else {
        auto textureY = createTexture(pixelBuffer, MTLPixelFormatR8Unorm, 0);
        auto textureUV = createTexture(pixelBuffer, MTLPixelFormatRG8Unorm, 1);
        if (!textureY || !textureUV || !matrix) {
            if (completion)
                completion(false);
            return false;
        }
        [renderEncoder setFragmentTexture:textureY atIndex:0];
        [renderEncoder setFragmentTexture:textureUV atIndex:1];
        [renderEncoder setFragmentBuffer:matrix offset:0 atIndex:0];
    }
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [renderEncoder endEncoding];

    CVPixelBufferRetain(pixelBuffer);
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb) {
      CVPixelBufferRelease(pixelBuffer);
      if (completion)
          completion(cb.status == MTLCommandBufferStatusCompleted);
    }];
    [commandBuffer presentDrawable:drawable];

    return true;
}

void MetalLayerRenderer::updatePixelBuffer(PixelBufferWrapper buffer, CompletionCallback comp) {
    std::lock_guard<decltype(mutex_)> lock(mutex_);
    if (this->pending_buffer_.buffer) {
        ++frame_dropped_;
        if ((frame_dropped_ - 1) % 15 == 0) {
            ByteViewRTCLogError(@"frame dropped %d", frame_dropped_);
        }
        if (this->pending_comp_) {
            this->pending_comp_(false);
            this->pending_comp_ = nullptr;
        }
    }
    this->pending_buffer_ = std::move(buffer);
    this->pending_comp_ = std::move(comp);
}

bool MetalLayerRenderer::tickRender(id<MTLCommandBuffer> commandBuffer) {
    mutex_.lock();
    if (is_drawing_ || !this->pending_buffer_.buffer) {
        mutex_.unlock();
        return false;
    }
    is_drawing_ = true;
    auto comp = std::move(this->pending_comp_);
    auto buffer = std::move(pending_buffer_);
    mutex_.unlock();

    auto selfptr = shared_from_this();
    auto completion = [selfptr, comp](bool success) {
        {
            std::lock_guard<decltype(selfptr->mutex_)> lock(selfptr->mutex_);
            assert(selfptr->is_drawing_);
            selfptr->is_drawing_ = false;
        }
        comp(success);
    };

    @autoreleasepool {
        return this->render(commandBuffer, std::move(buffer), this->layer_, std::move(completion));
    }
}

} // namespace byteview
