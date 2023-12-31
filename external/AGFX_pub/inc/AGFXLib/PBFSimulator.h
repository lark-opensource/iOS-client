//
//  PBFSimulator.hpp
//  Pods-RenderDemo
//
//  Created by lixiaoqi on 2020/4/8.
//

#ifndef PBFSimulator_hpp
#define PBFSimulator_hpp

#include <stdio.h>
#include "Runtime/RenderLib/Utils.h"
#include "Runtime/RenderLib/RendererDevice.h"
#include "Runtime/RenderLib/ComputerDevice.h"
#include "Context.h"

using AmazingEngine::ComputeEntity;
using AmazingEngine::ComputePipeline;
using AmazingEngine::ComputerDevice;
using AmazingEngine::Matrix4x4f;
using AmazingEngine::Vector3f;
using AmazingEngine::Vector4f;

struct getPoly6
{
    float coef, h2;
    getPoly6(float h)
    {
        h2 = h * h;
        float ih = 1.f / h;
        float ih3 = ih * ih * ih;
        float ih9 = ih3 * ih3 * ih3;
        coef = 315.f * ih9 / (64.f * M_PI);
    }

    float operator()(float r2)
    {
        if (r2 >= h2)
            return 0;
        float d = h2 - r2;
        return coef * d * d * d;
    }
};

struct Params
{
    int niter;
    float pho0;
    Vector3f g;
    float h;
    float rh; // rest density for fluid
    float dt;
    float lambda_eps;
    float delta_q;
    float k_corr;
    float n_corr;
    float k_boundaryDensity;
    float c_XSPH;

    float computeDensity()
    {
        int index = ceil(h / rh);
        float density = 0;
        getPoly6 poly6(h);
        for (int i = -index; i <= index; ++i)
        {
            for (int j = -index; j <= index; ++j)
            {
                for (int k = 0; k <= index; ++k)
                {
                    float r2 = i * i + j * j + k * k;
                    r2 *= rh * rh;
                    density += poly6(r2);
                }
            }
        }
        return density;
    }
};

// used to switch between the geometrical face and point cloud face
#define _GEOMETRY_

class AMAZING_EXPORT Simulator
{
public:
    Simulator(ComputerDevice* device,
              Params& params,
              Vector4f ulim,
              Vector4f llim);

    ~Simulator();

    /* TODO: may swap(d_pos, d_npos), i.e., the destination is assigned by Simulator, rather than caller */
    void step(Context& context, DeviceSequence seq);

    void loadParams(Params& params);

    void setLim(const Vector4f& ulim, const Vector4f& llim);

    void setFaceEclipse(Vector4f center, Vector4f radius);
    void setNoseEclipse(Vector4f center, Vector4f radius);

    void test(Context& ctx);

    // three rows of rotation matrix
    void setRotation(Vector3f r1, Vector3f r2, Vector3f r3);
    void setTranslation(Vector3f translation);

    void setOutput(DeviceBuffer output);
    void setNIteration(int niter);
    void setKcorr(float kcorr);
    void setNcorr(float ncorr);
    void setLambdaEps(float lambda_eps);
    void setGravity(const Vector3f& gravity);
    void setViscosity(float viscosity);
    void setDt(float dt);
    void setModelPosition(const Vector3f& pos);
    void setModelRadius(const Vector3f& radius);

    DeviceBuffer m_output = nullptr;
    DeviceBuffer d_gridStart = nullptr, d_gridEnd = nullptr;
    DeviceBuffer d_bgridStart = nullptr, d_bgridEnd = nullptr;

    DeviceBuffer d_p2gBufList = nullptr, d_p2gBufSize = nullptr;
    uint32_t p2gBufMaxSize = 40;

    ComputePipeline m_advectKernel_pipeline = nullptr;
    ComputePipeline m_computeGridRange_pipeline = nullptr;
    ComputePipeline m_computeLambda_pipeline = nullptr;
    ComputePipeline m_computePos_pipeline = nullptr;
    ComputePipeline m_computeXSPH_pipeline = nullptr;
    ComputePipeline m_updateVelocity_pipeline = nullptr;
    ComputePipeline m_computeGridId_pipeline = nullptr;
    ComputePipeline m_sortGridId_pipeline = nullptr;
    ComputePipeline m_sortbGridId_pipeline = nullptr;
    ComputePipeline m_computePos2_pipeline = nullptr;
    ComputePipeline m_transformObject_pipeline = nullptr;
    ComputePipeline m_reorderParticle_pipeline = nullptr;
    ComputePipeline m_swapUintBuffer_pipeline = nullptr;
    ComputePipeline m_swapFloat4Buffer_pipeline = nullptr;
    ComputePipeline m_swapFloatBuffer_pipeline = nullptr;
    ComputePipeline m_setUintInitValue_pipeline = nullptr;
    ComputePipeline m_computePos3_pipeline = nullptr;
    ComputePipeline m_countSort_pipeline = nullptr;
    ComputePipeline m_copyPosVelGrid_pipeline = nullptr;
    //    ComputePipeline m_copyPosVel_pipeline = nullptr;
    ComputePipeline m_setGridInitValue_pipeline = nullptr;
    ComputePipeline m_copyFloat4_pipeline = nullptr;

    ComputeEntity m_advectKernel_entity = nullptr;
    ComputeEntity m_computeGridRange_entity = nullptr;
    ComputeEntity m_computeLambda_entity = nullptr;
    ComputeEntity m_computePos_entity = nullptr;
    ComputeEntity m_computeXSPH_entity = nullptr;
    ComputeEntity m_updateVelocity_entity = nullptr;
    ComputeEntity m_computeGridId_entity = nullptr;
    ComputeEntity m_sortGridId_entity = nullptr;
    ComputeEntity m_sortbGridId_entity = nullptr;
    ComputeEntity m_computePos2_entity = nullptr;
    ComputeEntity m_transformObject_entity = nullptr;
    ComputeEntity m_reorderParticle_entity = nullptr;
    ComputeEntity m_swapUintBuffer_entity = nullptr;
    ComputeEntity m_swapFloat4Buffer_entity = nullptr;
    ComputeEntity m_swapFloatBuffer_entity = nullptr;
    ComputeEntity m_setUintInitValue_entity = nullptr;
    ComputeEntity m_computePos3_entity = nullptr;
    ComputeEntity m_countSort_entity = nullptr;
    ComputeEntity m_copyPosVelGrid_entity = nullptr;
    //    ComputeEntity m_copyPosVel_entity = nullptr;
    ComputeEntity m_setGridInitValue_entity = nullptr;
    ComputeEntity m_copyFloat4_entity = nullptr;

private:
    void advect(Context& context);
    void buildGridHash(Context& context);
    void correctDensity(Context& context);
    void correctVelocity(Context& context);
    void updateVelocity(Context& context);
    void swap(Context& context);

    void transformObject(Context& context);
    void buildBoundaryGridHash(Context& context);
    void correctDensity2(Context& context);
    void reorderParticle(Context& context);
    void buildGridHashCountSort(Context& context); // similiar to counting sort

    // approximate the face model as geometrical information
    void correctDensity3(Context& context);

    Vector3f m_gravity = Vector3f();
    float m_h = 0, m_dt = 0, m_pho0 = 0, m_lambda_eps = 0, m_delta_q = 0, m_k_corr = 0, m_n_corr = 0, m_k_boundaryDensity = 0, m_c_XSPH = 0;
    float m_coef_corr = 0;
    int m_niter = 0;
    Vector4f m_ulim = Vector4f(), m_llim = Vector4f();
    int m_gridHashDim[4] = {0, 0, 0, 0};
    float m_spiky_coef = 0, m_poly6_coef = 0;

    // three rows of rotation matrix and one translation
    Vector3f m_r1 = Vector3f(), m_r2 = Vector3f(), m_r3 = Vector3f(), m_t = Vector3f();

    // use basic geometry date to approximate the face model
    Vector4f m_bcenter = Vector4f();
    Vector4f m_bradius = Vector4f();
    Vector4f m_nose_center = Vector4f();
    Vector4f m_nose_radius = Vector4f();

    ComputerDevice* m_device = nullptr;
    DeviceSequence m_sequence = nullptr;

    void initPipelineEntity(ComputePipeline& pipeline, ComputeEntity& entity, std::string& shaderStr);

    void bufferMemCopy(DeviceBuffer dst, DeviceBuffer src, uint32_t len);

    void bufferMemSet(DeviceBuffer dst, int len, uint8_t value);
};

#endif /* PBFSimulator_hpp */
