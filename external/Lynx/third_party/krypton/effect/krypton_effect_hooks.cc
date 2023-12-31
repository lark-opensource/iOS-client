//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "krypton_effect_hooks.h"

#include "base/base_export.h"
#include "canvas/canvas_app.h"
#include "canvas/gpu/frame_buffer.h"
#include "canvas/gpu/gl/gl_api.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#include "canvas/util/texture_util.h"
#include "canvas/webgl/webgl_texture.h"
#include "effect/krypton_effect_helper.h"
#include "jsbridge/bindings/canvas/canvas_module.h"
#include "jsbridge/bindings/canvas/napi_webgl_texture.h"
#include "jsbridge/napi/native_value_traits.h"
#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace canvas {
namespace effect {

BASE_EXPORT GLContext** ThreadLocalAmazingContextPtr() {
  thread_local GLContext* amazing_context = nullptr;
  return &amazing_context;
}

BASE_EXPORT void GLStateSave(void* ctx) {
  (*ThreadLocalAmazingContextPtr())->MakeCurrent(nullptr);
}

BASE_EXPORT void GLStateRestore(void* ctx) {
  (*ThreadLocalAmazingContextPtr())->ClearCurrent();
}

BASE_EXPORT unsigned int GetTextureFunc(void* ctx, void* napi_js_texture) {
  GLStateSave(ctx);
  auto js_texture = static_cast<Napi::Value*>(napi_js_texture);
  if (!js_texture->IsObject() ||
      !js_texture->As<Napi::Object>().InstanceOf(
          NapiWebGLTexture::Constructor(js_texture->Env()))) {
    return 0;
  }

  auto webgl_texture = piper::NativeValueTraits<
      piper::IDLNullable<NapiWebGLTexture>>::NativeValue(*js_texture, 0);
  unsigned int tex = webgl_texture->GetTexCopyOnJsThread();

  GLStateRestore(ctx);
  return tex;
}

BASE_EXPORT void BeforeUpdateFunc(void* ctx, const unsigned int* input_texs,
                                  unsigned long input_texs_len,
                                  unsigned int output_tex) {
  auto sync_texure = [](unsigned int tex) {
    if (!tex) {
      return;
    }

    auto line = EffectHelper::Instance().FindEffectTextureRegistryLine(tex);
    if (!line || !(line->first) ||
        line->first->GetLastUpdateCounts() == line->second) {
      return;
    }
    auto webgl_tex = line->first;
    line->second = webgl_tex->GetLastUpdateCounts();
    webgl_tex->ForceFlushCommandbuffer();

    fml::AutoResetWaitableEvent sem;
    auto gpu_task_runner =
        CanvasModule::From(webgl_tex->Env())->GetCanvasApp()->gpu_task_runner();

    GLsync sync = GL::FenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);

    // glSync wiki https://www.khronos.org/opengl/wiki/Sync_Object
    // You need to ensure that the sync object is in the GPU's command queue. If
    // you don't, then you may create an infinite loop. Since glWaitSync
    // prevents the driver from adding any commands to the GPU command queue,
    // this would include the sync object itself if it has not yet been added to
    // the queue. This function does not take the GL_SYNC_FLUSH_COMMANDS_BIT, so
    // you have to do it with a manual glFlush call.
    GL::Flush();
    gpu_task_runner->PostTask([&sem, &sync, webgl_tex, tex]() {
      GL::WaitSync(sync, 0, GL_TIMEOUT_IGNORED);
      uint32_t src_tex = webgl_tex->related_id_.Get()->Get();

      ScopedGLResetRestore s(GL_TEXTURE_BINDING_2D);
      GLint min_filter, mag_filter, wrap_s, wrap_t;
      GL::BindTexture(GL_TEXTURE_2D, src_tex);
      GL::GetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, &min_filter);
      GL::GetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, &mag_filter);
      GL::GetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, &wrap_s);
      GL::GetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, &wrap_t);

      GL::BindTexture(GL_TEXTURE_2D, tex);
      GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, min_filter);
      GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, mag_filter);
      GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap_s);
      GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap_t);

      if (!TextureUtil::CopyTextureOnGPU(src_tex, tex, webgl_tex->width_,
                                         webgl_tex->height_)) {
        KRYPTON_LOGE("copy texture failed");
      }

      sync = GL::FenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
      GL::Flush();
      sem.Signal();
    });

    sem.Wait();
    GL::WaitSync(sync, 0, GL_TIMEOUT_IGNORED);
  };

  for (unsigned long i = 0; i < input_texs_len; i++) {
    sync_texure(input_texs[i]);
  }
  sync_texure(output_tex);
}

BASE_EXPORT void AfterUpdateFunc(void* ctx, const unsigned int* input_texs,
                                 unsigned long input_texs_len,
                                 unsigned int output_tex) {
  if (!output_tex) {
    return;
  }

  auto line =
      EffectHelper::Instance().FindEffectTextureRegistryLine(output_tex);
  auto webgl_tex = line->first;
  if (!webgl_tex) {
    return;
  }

  fml::AutoResetWaitableEvent sem;
  auto gpu_task_runner =
      CanvasModule::From(webgl_tex->Env())->GetCanvasApp()->gpu_task_runner();
  GLsync sync = GL::FenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
  GL::Flush();
  gpu_task_runner->PostTask([&sem, webgl_tex, output_tex, &sync]() {
    GL::WaitSync(sync, 0, GL_TIMEOUT_IGNORED);

    uint32_t dst_tex = webgl_tex->related_id_.Get()->Get();
    if (!TextureUtil::CopyTextureOnGPU(output_tex, dst_tex, webgl_tex->width_,
                                       webgl_tex->height_)) {
      KRYPTON_LOGE("copy texture failed");
    }

    sync = GL::FenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
    GL::Flush();
    sem.Signal();
  });

  sem.Wait();
  GL::WaitSync(sync, 0, GL_TIMEOUT_IGNORED);
}

BASE_EXPORT bool URLTranslate(const char* url, char* path, int* size,
                              void* ctx) {
  KRYPTON_LOGE("fallback to url translate, not implment");
  return false;
}

BASE_EXPORT void MakeSureAmazingContextCreated() {
  if (*ThreadLocalAmazingContextPtr() == nullptr) {
    *ThreadLocalAmazingContextPtr() = GLContext::CreateReal().release();
  }
}

}  // namespace effect
}  // namespace canvas
}  // namespace lynx
