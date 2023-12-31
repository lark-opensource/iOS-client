//
// Created by 黄清 on 2022/8/22.
//

#ifndef PRELOAD_VC_PORTRAIT_SUPPLIER_H
#define PRELOAD_VC_PORTRAIT_SUPPLIER_H
#include "vc_iportrait_supplier.h"

VC_NAMESPACE_BEGIN

class VCPortraitSupplier : public IVCPortraitSupplier {
public:
    VCPortraitSupplier();
    ~VCPortraitSupplier() override = default;

    void setSupplier(IVCPortraitSupplier *supplier);

public:
    void portraitChanged(VCStrCRef key);

public:
    VCJson getPortraits() override;
    VCJson getServePortraits() override;
    std::string getPortrait(VCStrCRef key) override;
    VCJson getGroupPortraits(VCStrCRef group) override;

private:
    IVCPortraitSupplier *imp = nullptr;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPortraitSupplier);
};

VC_NAMESPACE_END
#endif // PRELOAD_VC_PORTRAIT_SUPPLIER_H
