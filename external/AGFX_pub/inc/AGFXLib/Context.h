//
//  Context.hpp
//  Pods-RenderDemo
//
//  Created by lixiaoqi on 2020/4/3.
//

#ifndef Context_hpp
#define Context_hpp

#include <stdio.h>
#include "Runtime/RenderLib/RendererDevice.h"
#include "Runtime/RenderLib/ComputerDevice.h"

using AmazingEngine::ComputerDevice;

class AMAZING_EXPORT Context // 状态信息 | status information
{
public:
    Context(ComputerDevice* device, uint32_t nparticle = 0, uint32_t nbparticle = 0);
    ~Context();

    DeviceBuffer position() { return d_pos; }
    DeviceBuffer b_model_position() { return d_bmpos; }
    DeviceBuffer velocity() { return d_vel; }
    DeviceBuffer iid() { return d_iid; }
    uint32_t m_nparticle;

    DeviceBuffer b_position() { return d_bpos; }
    DeviceBuffer b_psi() { return d_bpsi; }
    DeviceBuffer b_iid() { return d_biid; }
    uint32_t m_nbparticle;

    static int MAX_FLUID_PARTICLE_NUM;
    static int MAX_MODEL_PARTICLE_NUM;

    //private:
    ComputerDevice* m_device;

    DeviceBuffer d_pos = nullptr, d_tpos = nullptr, d_npos = nullptr, d_vel = nullptr, d_nvel = nullptr;
    DeviceBuffer d_iid = nullptr;
    DeviceBuffer d_lambda = nullptr, d_pho = nullptr;

    DeviceBuffer d_pos_1 = nullptr, d_tpos_1 = nullptr, d_npos_1 = nullptr, d_vel_1 = nullptr, d_nvel_1 = nullptr;
    DeviceBuffer d_iid_1 = nullptr;

    DeviceBuffer d_gridId = nullptr, d_gridId_1 = nullptr;
    DeviceBuffer d_gridId_idx = nullptr;

    DeviceBuffer d_bpos = nullptr, d_bpsi = nullptr, d_biid = nullptr;
    DeviceBuffer d_bmpos = nullptr; // bounder model point positions
    DeviceBuffer d_bpos_1 = nullptr, d_bpsi_1 = nullptr, d_biid_1 = nullptr;
    DeviceBuffer d_bgridId = nullptr, d_bgridId_1 = nullptr;
    DeviceBuffer d_bgridId_idx = nullptr;

    DeviceBuffer d_bnormal = nullptr, d_bnormal_1 = nullptr;

    friend class Simulator;
};

#endif /* Context_hpp */
