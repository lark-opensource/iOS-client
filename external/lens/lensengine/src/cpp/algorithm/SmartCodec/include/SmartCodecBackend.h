//
// Created by Longtao Zhang on 2021/6/19.
//

#ifndef LENS_SmartCodecBACKEND_H
#define LENS_SmartCodecBACKEND_H
#include "LensBackendInterface.h"
#include "LensEngine.h"
#include "LensConfigType.h"

#ifdef TARGET_OS_IPHONE
#import "SmartCodecIOSInterface.h"
#include "LensDeserialize.h"
#elif defined(__ANDROID__)
#include "android/bd_macro.h"
#include "android/bd_smartcodec_sdk.h"
#include "android/AndroidHandler.h"
#include <GLES3/gl3.h>
#include <GLES2/gl2ext.h>
#include <gl/TextureDrawer.h>
#include "OclShareWrapper.h"
#include "TexturePoolMgr.h"
#include "android/OCLHelper.h"
#else
#include "nv_smart_codec.h"
#endif

using namespace LENS::FRAMEWORK;

namespace LENS {

    namespace ALGORITHM {

        class SmartCodecBackend:public ILensBackendInterface {
        public:
            SmartCodecBackend();
            virtual ~SmartCodecBackend();

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
            int srcWidth_;
            int srcHeight_;
            const char* model_path_;
#ifdef TARGET_OS_IPHONE
            SmartCodecIOSInterface *iOSHandle_;
            LensDeserialize streamObject;
#elif defined(__ANDROID__)
            // for android
            GLuint CreateTexture(int width, int height);
            Handle m_codec_param_predictor = nullptr;
            VideoSmartCodec::AndroidHandler* m_androidHandler = nullptr;
            GLuint inputTexture_;
            TextureDrawer *drawerPtr_;
            TexturePoolMgr *texturePool_;
            bool  isExtOESTexture_;
            int CurFrameIdx_ = 0;
            void* m_pRGBAData = nullptr;
            std::string mFeatRunType;
            OCLEnv* m_pOCLEnv = nullptr;
            int mCurFrameIdx = 0;
            int mStride = 0;
            cl_mem mOclImage2d = nullptr;
#else
            void* m_codec_param_predictor;
#endif      

        };

    } /* namespace ALGORITHM */
} /* namespace LENS */

#endif //LENS_SmartCodecBACKEND_H
