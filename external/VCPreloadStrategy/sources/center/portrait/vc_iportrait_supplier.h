//
// Created by 黄清 on 2022/8/22.
//

#ifndef PRELOAD_IVCPORTRAITSUPPLIER_H
#define PRELOAD_IVCPORTRAITSUPPLIER_H
#include "vc_base.h"
#include "vc_json.h"

VC_NAMESPACE_BEGIN

namespace PortraitName {
extern const char *play;
extern const char *preload;
} // namespace PortraitName

class IVCPortraitSupplier {
public:
    virtual std::string getPortrait(VCStrCRef key) = 0;
    virtual VCJson getPortraits() = 0;
    virtual VCJson getServePortraits() = 0;
    virtual VCJson getGroupPortraits(VCStrCRef group) = 0;

public:
    virtual ~IVCPortraitSupplier() = default;
};

VC_NAMESPACE_END

// IVCPortraitSupplier.h
#endif // PRELOAD_IVCPORTRAITSUPPLIER_H
