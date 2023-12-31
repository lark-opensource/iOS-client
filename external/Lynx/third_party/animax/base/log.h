// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_BASE_LOG_H_
#define ANIMAX_BASE_LOG_H_

#include "Lynx/base/log/logging.h"

#define ANIMAX_LOGV(msg) LOGV("[AnimaX] " msg)
#define ANIMAX_LOGI(msg) LOGI("[AnimaX] " msg)
#define ANIMAX_LOGW(msg) LOGW("[AnimaX] " msg)
#define ANIMAX_LOGE(msg) LOGE("[AnimaX] " msg)

#define ANIMAX_CONSTRUCTOR_LOG(class_name) \
  ANIMAX_LOGI(#class_name " constructor ") << this
#define ANIMAX_DESTRUCTOR_LOG(class_name) \
  ANIMAX_LOGI(#class_name " destructor ") << this

#endif  // ANIMAX_BASE_LOG_H_
