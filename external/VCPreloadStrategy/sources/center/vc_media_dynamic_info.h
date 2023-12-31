//
//  vc_media_dynamic_info.hpp

#ifndef vc_media_dynamic_info_hpp
#define vc_media_dynamic_info_hpp
#pragma once

#include "vc_base.h"
#include <stdio.h>
#include <string>

VC_NAMESPACE_BEGIN

class IVCMediaDynamicInfo {
public:
    virtual ~IVCMediaDynamicInfo(){};

public:
    virtual LongValueMap getMediaLongValue(VCStrCRef mediaId) = 0;
    virtual FloatValueMap getMediaFloatValue(VCStrCRef mediaId) = 0;
};

VC_NAMESPACE_END

#endif /* vc_media_dynamic_info_hpp */
