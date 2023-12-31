//
// Created by 黄清 on 2021/11/13.
//

#ifndef PRELOAD_VC_PLAY_BUFFER_ST_INTERFACE_H
#define PRELOAD_VC_PLAY_BUFFER_ST_INTERFACE_H

#pragma once
#include "vc_istrategy.h"
VC_NAMESPACE_BEGIN

class IVCPlayBufferInterface : public IVCStrategy, public IVCPlayBufferControl {
public:
    IVCPlayBufferInterface(const std::string &name) :
            IVCStrategy(VCModuleTypePlayBufferControl, name){};
    ~IVCPlayBufferInterface() override = default;
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_PLAY_BUFFER_ST_INTERFACE_H
