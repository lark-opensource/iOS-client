// Copyright (c) 2022 The Lynx Authors. All rights reserved.

#include "canvas/gpu/gl_initializer.h"

#include "canvas/base/log.h"
#include "canvas/gpu/gl_global_device_attributes.h"

namespace lynx {
namespace canvas {

GLInitializer::GLInitializer() : initialized(false) {
  KRYPTON_CONSTRUCTOR_LOG(GLInitializer);
}

GLInitializer &GLInitializer::Instance() {
  static GLInitializer *instance = new GLInitializer();
  return *instance;
}

bool GLInitializer::InitOnJSThreadBlocked(
    const fml::RefPtr<fml::TaskRunner> &gpu_task_runner) {
  return InitImpl(gpu_task_runner, true);
}

bool GLInitializer::InitOnJSThreadAsync(
    const fml::RefPtr<fml::TaskRunner> &gpu_task_runner) {
  return InitImpl(gpu_task_runner, false);
}

bool GLInitializer::InitImpl(
    const fml::RefPtr<fml::TaskRunner> &gpu_task_runner, bool sync) {
  KRYPTON_LOGI("InitImpl with sync? ") << sync;

  if (initialized) {
    KRYPTON_LOGI("InitImpl but initialized");
    return true;
  }

  if (sync) {
    gpu_task_runner->PostSyncTask([this]() { InitOnGPU(); });
    return initialized;
  } else {
    gpu_task_runner->PostTask([this]() { InitOnGPU(); });
    return true;
  }
}

void GLInitializer::InitOnGPU() {
  if (initialized) {
    KRYPTON_LOGI("InitOnGPU but initialized");
    return;
  }

  auto ctx = GLContext::CreateVirtual();
  ctx->Init();
  ctx->MakeCurrent(nullptr);
  initialized = GLGlobalDeviceAttributes::Instance().InitOnGPU();

  KRYPTON_LOGW("InitOnGPU with result ") << initialized;
}

}  // namespace canvas
}  // namespace lynx
