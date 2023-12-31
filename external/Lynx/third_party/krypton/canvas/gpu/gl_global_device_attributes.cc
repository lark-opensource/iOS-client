// Copyright 2021 The Lynx Authors. All rights reserved.

#include "gl_global_device_attributes.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
GLGlobalDeviceAttributes::GLGlobalDeviceAttributes()
    : inited_(false), valid_(false) {}

GLGlobalDeviceAttributes &GLGlobalDeviceAttributes::Instance() {
  static auto *instance = new GLGlobalDeviceAttributes();
  return *instance;
}

bool GLGlobalDeviceAttributes::InitOnGPU() {
  std::lock_guard<std::mutex> lock_guard(attributes_mutex_);

  if (inited_ && valid_) {
    return true;
  }

  device_attributes_.Init();

  // check if really inited, it may fail if gl context is invalid
  valid_ = device_attributes_.max_texture_size_ > 0;

  if (inited_) {
    KRYPTON_LOGW("Init GLDeviceAttributes another try with res ") << valid_;
  }

  inited_ = true;

  return valid_;
}

bool GLGlobalDeviceAttributes::Inited() {
  std::lock_guard<std::mutex> lock_guard(attributes_mutex_);
  return inited_;
}

bool GLGlobalDeviceAttributes::Valid() {
  std::lock_guard<std::mutex> lock_guard(attributes_mutex_);
  return valid_;
}

bool GLGlobalDeviceAttributes::InitedButFailed() {
  std::lock_guard<std::mutex> lock_guard(attributes_mutex_);
  return inited_ && !valid_;
}

GLDeviceAttributes GLGlobalDeviceAttributes::GetDeviceAttributes() {
  std::lock_guard<std::mutex> lock_guard(attributes_mutex_);
  DCHECK(inited_ && valid_);
  return device_attributes_;
}

const GLDeviceAttributes &GLGlobalDeviceAttributes::GetDeviceAttributesRef() {
  std::lock_guard<std::mutex> lock_guard(attributes_mutex_);
  DCHECK(inited_ && valid_);
  return device_attributes_;
}
}  // namespace canvas
}  // namespace lynx
