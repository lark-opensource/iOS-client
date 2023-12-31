/**
 * @file MaterialType.h
 * @author Andrew Wu (andrew.wu@bytedance.com)
 * @brief 材质模式定义 | Material mode definition
 * @version 1.0.0
 * @date 2019-11-13
 * @copyright Copyright (c) 2019
 */
#pragma once

#include "Gaia/AMGPrerequisites.h"
#include "Runtime/RenderLib/VertexAttribDesc.h"

#include <unordered_map>

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief [已废弃] 渲染队列 | [Deprecated] Render queue
 */
enum class RenderQueue
{
    BACKGROUND = 1000,
    GEOMETRY = 2000,
    ALPHA_TEST = 2450,
    TRANSPRENT = 3000,
    OVERLAY = 4000,
};

//enum class RenderType {
//    INVALID,
//    OPAQUE,
//    TRANSPRENT,
//    TRANSPRENT_CUTOUT,
//    BACKGROUND,
//    OVERLAY,
//};

#define AE_RENDER_TYPE_OPAQUE "Opaque"
#define AE_RENDER_TYPE_TRANSPRENT "Transparent"
#define AE_RENDER_TYPE_TRANSPRENT_CUTOUT "TransparentCutout"
#define AE_RENDER_TYPE_BACKGROUND "Background"
#define AE_RENDER_TYPE_OVERLAY "Overlay"

/**
 * @brief 常数类型 | Constant type
 * Not used by exposed API
 */
enum class AMGUniformType
{
    REAL,
    VEC2,
    VEC3,
    VEC4,
    MAT3,
    MAT4,
    REAL_ARRAY,
    VEC2_ARRAY,
    VEC3_ARRAY,
    VEC4_ARRAY,
    SAMPLER,
};

/**
 * @brief 着色器类型 | Shader type
 * Currently support Vertex Fragment Compute
 */
enum class AMGShaderType
{
    NONE = 0,
    VERTEX,
    FRAGMENT,
    COMPUTE,
    BINARY_PROGRAM,
    COUNT
};

/**
 * @brief 纹理地址寻址模式 | Texture address addressing mode
 * REPEAT: The integer part of the coordinate will be ignored and a repeating pattern is formed.
 * MIRRORED: The texture will also be repeated, but it will be mirrored when the integer part of the coordinate is odd.
 * CLAMP: The coordinate will simply be clamped between 0 and 1.
 * BORDER: The coordinates that fall outside the range will be given a specified border color.
 */
enum class AMGWrapMode
{
    REPEAT,
    CLAMP,
    BORDER,
    MIRROR,
};

/**
 * @brief 纹理过滤模式 | Texture filter mode
 * NEAREST Returns the value of the texture element that is nearest (in Manhattan distance) to the specified texture coordinates.
 * LINEAR Returns the weighted average of the four texture elements that are closest to the specified texture coordinates.
 */
enum class AMGFilterMode
{
    INVALID = -1,
    NEAREST,
    LINEAR,
};

/**
 * @brief 纹理mipmap过滤模式 | Texture mipmap filter mode
 * Same as below
 */
enum class AMGFilterMipmapMode
{
    NONE = 0,
    NEAREST,
    LINEAR,
};

/**
 * @brief [已废弃] 纹理比较模式 | [Deprecated] Texture comparison mode
 */
enum class TextureCompareMode
{
    NONE = 0,
    REF_TO_TEXTURE,
};

/**
 * @brief 顶点属性映射表 | Vertex attribute mapping table
 * Used for pipeline reflection
 */
class VertexAttribMapWrap
{
public:
    /**
     * @brief 顶点属性映射表构造 | Vertex attribute mapping table construction
     */
    VertexAttribMapWrap() = default;
    /**
     * @brief 顶点属性映射表构造 | Vertex attribute mapping table construction
     * @param attribMap Vertex attribute mapping
     */
    VertexAttribMapWrap(std::unordered_map<std::string, AMGVertexAttribType> attribMap)
        : m_AttribMap(std::move(attribMap))
    {
    }
    /**
     * @brief 获取顶点属性 | Get vertex attributes
     * @param name vertex input attribute name
     * @return AMGVertexAttribType vertex input attribute type
     */
    virtual AMGVertexAttribType getVertexAttribType(char* name) const
    {
        auto iter = m_AttribMap.find(name);
        if (iter != m_AttribMap.end())
        {
            return iter->second;
        }
        else
        {
            return AMGVertexAttribType::UNKOWN;
        }
    }
    /**
     * @brief 设置顶点属性 | Set vertex attributes
     * @param name vertex input attribute name
     * @param type vertex input attribute type
     */
    virtual void setAttribType(std::string const& name, AMGVertexAttribType type)
    {
        m_AttribMap[name] = type;
    }

protected:
    // 顶点属性映射表 | Vertex attribute mapping table
    std::unordered_map<std::string, AMGVertexAttribType> m_AttribMap;
};

NAMESPACE_AMAZING_ENGINE_END
