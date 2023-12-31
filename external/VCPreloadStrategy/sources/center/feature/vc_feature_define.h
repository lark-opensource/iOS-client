//
// Created by 黄清 on 2022/9/4.
//

#ifndef PRELOAD_VC_FEATURE_DEFINE_H
#define PRELOAD_VC_FEATURE_DEFINE_H
#pragma once

#include "vc_base.h"

VC_NAMESPACE_BEGIN

typedef enum {
    VCFeatureTypeKV,
    VCFeatureTypeSeq
} VCFeatureType;

namespace FeatureGroup {
extern const char *play;
extern const char *preload;
extern const char *settings;
} // namespace FeatureGroup

VC_NAMESPACE_END

#endif // PRELOAD_VC_FEATURE_DEFINE_H
