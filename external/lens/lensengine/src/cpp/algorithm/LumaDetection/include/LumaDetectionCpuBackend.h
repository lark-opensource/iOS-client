/*
 * huangpan.hp@bytedance.com
 * 2020.6.16
 */

#ifndef _DETECTION_CPU_BACKEND_IMPLE_H_
#define _DETECTION_CPU_BACKEND_IMPLE_H_

#include "LensConfigType.h"
#include "hdr_detect_export.h"
#include "../../../framework/core/include/LensBackendInterface.h"

#ifdef TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
#import <OpenGLES/ES3/gl.h>
#import <Metal/Metal.h>
#include "metal_shader.h"
#endif

using namespace LENS::FRAMEWORK;

namespace LENS {

namespace ALGORITHM {

    class LumaDetectionCpuBackend: public ILensBackendInterface {
    public:
        LumaDetectionCpuBackend();
        virtual ~LumaDetectionCpuBackend();

    public:

        LensCode SetAsyncOutputListener(std::shared_ptr<ILensAsyncOutputListener> listener) override;

        LensCode InitBackend(void* param) override;

        LensCode ExecuteStream(std::vector<void*> &in_buffers,void* param) override;

        LensCode ExecuteStream(void* in_buffer,void* param) override;

        LensCode ExecuteTexture(std::vector<int> &in_textures,void* param) override;

        LensCode ExecuteTexture(int in_texture,void* param) override;

        LensCode GetStreamOutput(std::vector<void*>* out_buffers,void* attr) override;

        LensCode GetStreamOutput(void* out_buffer,void* attr) override;

        LensCode GetTextureOutput(std::vector<int>* out_textures,void* attr) override;

        LensCode GetTextureOutput(int* out_texture,void* attr) override;

        LensCode SetInputProperty(void* attr) override;

        LensCode GetOutputProperty(void* attr) override;

        LensCode UnInitBackend() override;

    private:
#ifdef TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
        bool IsGLContext();
        int initGL(int width, int height);
        bool convertNV12Pixelbuffer2RBGA(CVPixelBufferRef nv12PixelBuffer);
        bool convertBGRAPixelbuffer2RBGA(CVPixelBufferRef BGRAPixelBuffer);
#endif
    private:
        std::shared_ptr<hdr_detect_export> handle_;
        bool useExp_ = false;
        
        bool contextISCreated_ = true;
        int textureID_;

        int luma_trigger1_ = 0;
        int luma_trigger2_ = 0;
        int luma_trigger3_ = 0;
        int luma_trigger4_ = 0;
        float luma_trigger_ = 0.f;
        LensDataFormat pixelFmt_;

#ifdef TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
        EAGLContext *context_;
        CVOpenGLESTextureCacheRef textureCache_;
        CVMetalTextureCacheRef metalTextureCache_;
        id<MTLDevice> device_;
        id<MTLLibrary> library_;
        id<MTLCommandQueue> commandQueue_;

        CVPixelBufferRef rgbaPixelBuffer_;
        id<MTLTexture> rgbaTexture_;
        id<MTLComputePipelineState> pipeline_;
        id<MTLComputePipelineState> pipelineBGRA2RGBA_;
        int width_;
        int height_;
#endif
    };

} /* namespace ALGORITHM */

} /* namespace LENS */

#endif //_ONEKEY_DETECTION_CPU_BACKEND_IMPLE_H_
