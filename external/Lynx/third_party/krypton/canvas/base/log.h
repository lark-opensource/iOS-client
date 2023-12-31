// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_BASE_LOG_H_
#define CANVAS_BASE_LOG_H_

#include "base/log/logging.h"

// as lynx do not have NDEBUG macro on iOS, DLOG & LOG have no difference ..
// #define KRYPTON_DLOGV(msg) DLOGV("[Krypton] " msg)
// #define KRYPTON_DLOGI(msg) DLOGI("[Krypton] " msg)
// #define KRYPTON_DLOGW(msg) DLOGW("[Krypton] " msg)
// #define KRYPTON_DLOGE(msg) DLOGE("[Krypton] " msg)
// #define KRYPTON_DLOGF(msg) DLOGF("[Krypton] " msg)

#define KRYPTON_LOGV(msg) LOGV("[Krypton] " msg)
#define KRYPTON_LOGI(msg) LOGI("[Krypton] " msg)
#define KRYPTON_LOGW(msg) LOGW("[Krypton] " msg)
#define KRYPTON_LOGE(msg) LOGE("[Krypton] " msg)
#define KRYPTON_LOGF(msg) LOGF("[Krypton] " msg)

#define KRYPTON_CONSTRUCTOR_LOG(class_name) \
  KRYPTON_LOGI(#class_name " constructor ") << this
#define KRYPTON_DESTRUCTOR_LOG(class_name) \
  KRYPTON_LOGI(#class_name " destructor ") << this

#endif  // CANVAS_BASE_LOG_H_
