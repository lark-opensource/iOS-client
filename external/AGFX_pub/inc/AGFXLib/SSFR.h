//
//  SSFR.hpp
//  Pods-RenderDemo
//
//  Created by lixiaoqi on 2020/4/17.
//
//  fluid rendering algorithm: Screen Space Fluid Rendering

#if 0

#ifndef SSFR_hpp
#define SSFR_hpp

#include <stdio.h>
//#include "Demo.h"
#include "Runtime/RenderLib/RendererDevice.h"
#include "Runtime/RenderLib/ComputerDevice.h"
//#include "AMGPrerequisites.h"

using AmazingEngine::GeometryDesc;
using AmazingEngine::Matrix4x4f;
using AmazingEngine::RenderEntity;
using AmazingEngine::RendererDevice;
using AmazingEngine::RenderPipeline;
using AmazingEngine::VertexAttribMapWrap;

extern Matrix4x4f makePerspectiveMatrix(float fovy, float aspect, float near, float far);
extern Matrix4x4f makeXRotationMatrix(Matrix4x4f& matrix, float angle);
extern Matrix4x4f makeYRotationMatrix(Matrix4x4f& matrix, float angle);
extern Matrix4x4f makeCameraView();

class AMAZING_EXPORT SSFR
{
public:
    SSFR() {}
    ~SSFR() {} // TODO release the memory
    void init(RendererDevice* device, int width, int height, DeviceTexture reflectImage, int renderMode);
    void onSizeChange(int width, int height);
    // the output will be specified from the output?
    void render(DeviceTexture inputID, DeviceTexture outputID, DeviceBuffer particleBuffer, int num);

private:
    RendererDevice* m_device = nullptr;
    int m_windowWidth, m_windowHeight;
    float m_render_scale = 0.5; // scale down the intermediate texture
    int m_renderMode = 0;       // 0: water  1: matellic material

    GeometryDesc m_get_depth_geometry;
    RenderPipeline m_get_depth_pipeline;
    RenderEntity m_get_depth_entity;
    DeviceTexture m_get_depth_texture_a;
    DeviceTexture m_get_depth_texture_b;
    DeviceTexture m_reflect_texture;
    DeviceTexture m_metal_texture;
    DeviceFramebuffer m_get_depth_fbo = 0;

    GeometryDesc m_get_thick_geometry;
    RenderPipeline m_get_thick_pipeline;
    RenderEntity m_get_thick_entity;
    DeviceTexture m_get_thick_texture;
    DeviceFramebuffer m_get_thick_fbo = 0;

    GeometryDesc m_smooth_depth_geometry;
    RenderPipeline m_smooth_depth_pipeline;
    RenderEntity m_smooth_depth_entity;
    DeviceFramebuffer m_smooth_depth_fbo_a = 0;
    DeviceFramebuffer m_smooth_depth_fbo_b = 0;

    GeometryDesc m_restore_normal_geometry;
    RenderPipeline m_restore_normal_pipeline;
    RenderEntity m_restore_normal_entity;
    DeviceTexture m_restore_normal_texture;
    DeviceFramebuffer m_restore_normal_fbo = 0;

    GeometryDesc m_shading_geometry;
    RenderPipeline m_shading_pipeline;
    RenderEntity m_shading_entity;
    DeviceFramebuffer m_shading_fbo = 0;

    GeometryDesc m_glass_shading_geometry;
    RenderPipeline m_glass_shading_pipeline;
    RenderEntity m_glass_shading_entity;
    DeviceFramebuffer m_glass_shading_fbo = 0;

    GeometryDesc m_display_geometry;
    RenderPipeline m_display_pipeline;
    RenderEntity m_display_entity;
    DeviceBuffer buffer_quad;
    DeviceFramebuffer m_display_fbo = 0;

    DeviceSequence m_seq;
    DeviceTexture depthBuffer = nullptr;
    DeviceTexture depthBuffer2 = nullptr;
    DeviceTexture depthBuffer3 = nullptr;
    DeviceTexture reflect_texture = nullptr;
    DeviceTexture metal_texture = nullptr;
    DeviceTexture water_texture = nullptr;

    RenderPipeline createPipeline(std::string const& vs, std::string const& ps, VertexAttribMapWrap const& semantics);
};

#endif /* SSFR_hpp */

#endif
