/**
 * @file PipelineState.h
 * @author Andrew Wu (andrew.wu@bytedance.com)
 * @brief 渲染状态定义 | Rendering state definition
 * @version 1.0.0
 * @date 2019-11-13
 * @copyright Copyright (c) 2019 Bytedance Inc. All rights reserved.
 */
#ifndef PipelineState_h
#define PipelineState_h

#include "Gaia/AMGSharePtr.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief 缓存类型 | Cache type
 */
enum class BufferType
{
    /**
     * @brief Vertex Buffer 
     */
    VERTEX_BUFFER = 0,
    /**
     * @brief Index Buffer
     */
    INDEX_BUFFER,
    /**
     * @brief Pixel Pack Buffer For draw to image
     */
    PIXEL_PACK_BUFFER,
    /**
     * @brief Pixel Unpack Buffer For read from image
     */
    PIXEL_UNPACK_BUFFER,
    /**
     * @brief Transform Feedback buffer
     */
    TRANSFORM_OUTPUT_BUFFER,
    /**
     * @brief Uniform Buffer
     */
    UNIFORM_BUFFER,
    /**
     * @brief Indirect Draw Buffer (Currently Not Be Used)
     */
    INDIRECT_BUFFER,
    /**
     * @brief Count Buffer For Compute Pipeline
     */
    COUNTER_BUFFER,
    /**
     * @brief Shader Storage Buffer
     */
    STORAGE_BUFFER,
    /**
     * @brief Staging Buffer For Internal Usage
     */
    STAGING_BUFFER,
    BufferTypeCount
};

/**
 * @brief 缓存用途 | Cache purpose
 */
enum class BufferUsage
{
    /**
     * @brief Static Draw Without Change After Init
     * Often GPU-Only DeviceMemory
     * update static buffer is very slow
     */
    STATIC_DRAW = 0,
    /**
     * @brief Dynamic Draw With Change Once Per Frame
     * Often GPU-CPU DeviceMemory
     */
    DYNAMIC_DRAW = 1,
    /**
     * @brief Dynamic Draw With Change Mutiple Per Frame
     * Often CPU-Courent DeviceMemory
     */
    DYNAMIC_CHANGE = 2,
    USAGE_MAX,
};

/**
 * @brief 填充模式 | Fill mode
 */
enum class AMGPolygonMode
{
    /**
     * @brief Draw Fill Internal
     */
    FILL = 0,
    /**
     * @brief [Deprecated]
     */
    LINE,
    /**
     * @brief Draw Vertex Point
     */
    POINT
};

/**
 * @brief 正面绕向 | Head-on
 */
enum class AMGFrontFace
{
    COUNTER_CLOCKWISE = 0,
    CLOCKWISE
};

/**
 * @brief 剔除模式 | Culling mode
 */
enum class AMGCullFace
{
    NONE = 0,
    FRONT,
    BACK,
    FRONT_AND_BACK,
};

/**
 * @brief 采样数目模式 | Sample number mode
 * Just Like https://www.khronos.org/registry/vulkan/specs/1.2-extensions/man/html/VkSampleCountFlagBits.html
 */
enum class AMGSampleCountFlagBits
{
    BIT_1 = 0x00000001,
    BIT_2 = 0x00000002,
    BIT_4 = 0x00000004,
    BIT_8 = 0x00000008,
    BIT_16 = 0x00000010,
    BIT_32 = 0x00000020,
    BIT_64 = 0x00000040,
    BITS_MAX = 0x7FFFFFFF
};

/**
 * @brief 比较模式 | Comparison mode
 * Just Like https://www.khronos.org/registry/vulkan/specs/1.2-extensions/man/html/VkCompareOp.html
 */
enum class AMGCompareOp
{
    NEVER = 0,
    LESS = 1,
    EQUAL = 2,
    LESS_OR_EQUAL = 3,
    GREATER = 4,
    NOT_EQUAL = 5,
    GREATER_OR_EQUAL = 6,
    ALWAYS = 7,
    MAX_ENUM = 0x7FFFFFFF
};

/**
 * @brief 模版操作模式 | Template operation mode
 * Just Like https://www.khronos.org/registry/vulkan/specs/1.2-extensions/man/html/VkStencilOp.html
 */
enum class AMGStencilOp
{
    KEEP = 0,
    ZERO = 1,
    REPLACE = 2,
    INCREMENT_AND_CLAMP = 3,
    DECREMENT_AND_CLAMP = 4,
    INVERT = 5,
    INCREMENT_AND_WRAP = 6,
    DECREMENT_AND_WRAP = 7,
    MAX_ENUM = 0x7FFFFFFF
};

/**
 * @brief 混合模式 | Mixed mode
 * Just Like https://www.khronos.org/registry/vulkan/specs/1.2-extensions/man/html/VkBlendOp.html
 */
enum class AMGBlendOp
{
    ADD = 0,
    SUB,
    REVSUB,
    MIN,
    MAX,
};

/**
 * @brief 混合因子 | Mixing factor
 * Just Like https://www.khronos.org/registry/vulkan/specs/1.2-extensions/man/html/VkBlendFactor.html
 */
enum class AMGBlendFactor
{
    ZERO = 0,
    ONE,
    SRC_COLOR,
    ONE_MINUS_SRC_COLOR,
    DST_COLOR,
    ONE_MINUS_DST_COLOR,
    SRC_ALPHA,
    ONE_MINUS_SRC_ALPHA,
    DST_ALPHA,
    ONE_MINUS_DST_ALPHA,
    CONST_COLOR,
    ONE_MINUS_CONST_COLOR,
    CONST_ALPHA,
    ONE_MINUS_CONST_ALPHA,
};

/**
 * @brief 颜色通道开关 | Color channel switch
 * Just Like https://www.khronos.org/registry/vulkan/specs/1.2-extensions/man/html/VkColorComponentFlagBits.html
 */
enum class AMGColorMask
{
    R = 0x1,
    G = 0x2,
    B = 0x4,
    A = 0x8
};

/**
 * @brief 逻辑操作模式 | Logical operation mode
 * Just Like https://www.khronos.org/registry/vulkan/specs/1.2-extensions/man/html/VkLogicOp.html
 */
enum class AMGLogicOp
{
    CLEAR = 0,
    AND = 1,
    AND_REVERSE = 2,
    COPY = 3,
    AND_INVERTED = 4,
    NO_OP = 5,
    XOR = 6,
    OR = 7,
    NOR = 8,
    EQUIVALENT = 9,
    INVERT = 10,
    OR_REVERSE = 11,
    COPY_INVERTED = 12,
    OR_INVERTED = 13,
    NAND = 14,
    SET = 15,
    MAX_ENUM = 0x7FFFFFFF
};

#define DYNAMIC_STATE_VIEWPORT 0x00000001
#define DYNAMIC_STATE_SCISSOR 0x00000002

/**
 * @brief 视口状态 | Viewport state
 */
struct PipelineViewport : public RefBase
{
    float x = 0.0f;        ///< 视口起点横坐标 | The abscissa of the starting point of the viewport
    float y = 0.0;         ///< 视口起点纵坐标 | The ordinate of the viewport start point
    float width = 0.0f;    ///< 视口宽度 | Viewport width
    float height = 0.0f;   ///< 视口高度 | Viewport height
    float minDepth = 0.0f; ///< 最小深度 | Minimum depth
    float maxDepth = 1.0f; ///< 最大深度 | Maximum depth
};

/**
 * @brief 裁剪状态 | Crop state
 */
struct PipelineScissor : public RefBase
{
    float x = 0;         ///< 裁剪起点横坐标 | The abscissa of the starting point of clipping
    float y = 0;         ///< 裁剪起点纵坐标 | Y coordinate of starting point
    float width = 1.0f;  ///< 裁剪宽度 | Crop width
    float height = 1.0f; ///< 裁剪高度 | Cutting height
};

/**
 * @brief 光栅化状态 | Rasterization state
 */
struct PipelineRasterization : public RefBase
{
    bool depthClampEnable = false;                            ///< 深度裁剪开关 | Depth crop switch
    bool rasterizerDiscardEnable = false;                     ///< 光栅化丢弃开关 | Rasterization discard switch
    AMGPolygonMode polygonMode = AMGPolygonMode::FILL;        ///< 填充模式 | Fill mode
    AMGCullFace cullMode = AMGCullFace::NONE;                 ///< 剔除模式 | Culling mode
    AMGFrontFace frontFace = AMGFrontFace::COUNTER_CLOCKWISE; ///< 正面绕向 | Head-on
    bool depthBiasEnable = false;                             ///< 深度偏移开关 | Depth migration switch
    float depthBiasConstantFactor = 0.0f;                     ///< 深度偏移常数项 | Depth migration constant
    float depthBiasClamp = 1.0f;                              ///< 深度偏移裁剪 | Depth offset crop
    float depthBiasSlopeFactor = 1.0f;                        ///< 深度偏移斜率 | Depth migration slope
    float lineWidth = 1.0f;                                   ///< 线宽 | Line width
};

/**
 * @brief 多重采样状态 | Multiple sampling state
 */
struct PipelineMultisample : public RefBase
{
    AMGSampleCountFlagBits rasterizationSamples = AMGSampleCountFlagBits::BIT_1; ///< 多重采样模式(尚未支持) | Multiple sampling mode (not supported yet)
    bool sampleShadingEnable = false;                                            ///< 采样计算开关(尚未支持) | Sampling calculation switch (not supported yet)
    float minSampleShading = 0.0;                                                ///< 采样计算最小值(尚未支持) | Sample calculation minimum (not supported yet)
    uint32_t* sampleMasks = nullptr;                                             ///< 采样遮罩(尚未支持) | Sampling mask (not supported yet)
    bool alphaToCoverageEnable = false;                                          ///< alpha转覆盖率开关 | Alpha to coverage switch
    bool alphaToOneEnable = false;                                               ///< alpha转1开关(尚未支持) | alpha to 1 switch (not supported yet)
};

/**
 * @brief 模版操作模式 | Template operation mode
 */
struct PipelineStencilOp : public RefBase
{
    AMGStencilOp failOp = AMGStencilOp::KEEP;      ///< 模版测试失败操作 | Template test failed operation
    AMGStencilOp passOp = AMGStencilOp::KEEP;      ///< 模版测试通过操作 | Template test pass operation
    AMGStencilOp depthFailOp = AMGStencilOp::KEEP; ///< 深度测试失败操作 | Depth test failed operation
    AMGCompareOp compareOp = AMGCompareOp::ALWAYS; ///< 模版测试比较模式 | Template test comparison mode
    uint32_t compareMask = 0xFFFFFFFF;             ///< 模版测试比较模版 | Template test comparison template
    uint32_t writeMask = 0xFFFFFFFF;               ///< 模版测试写模版 | Template test write template
    uint32_t reference = 0;                        ///< 模版测试参考值 | Template test reference value
};

/**
 * @brief 深度模版状态 | In-depth template status
 */
struct PipelineDepthStencil : public RefBase
{
    bool depthTestEnable = false;                       ///< 深度测试开关 | Depth test switch
    bool depthWriteEnable = true;                       ///<深度测试写开关 | Depth test write switch
    AMGCompareOp depthCompareOp = AMGCompareOp::LESS;   ///< 深度测试比较模式 | In-depth test comparison mode
    bool stencilTestEnable = false;                     ///< 模版测试开关 | Template test switch
    SharePtr<PipelineStencilOp> stencilFront = nullptr; ///< 正面模版测试状态 | Positive template test status
    SharePtr<PipelineStencilOp> stencilBack = nullptr;  ///< 背面模版测试状态 | Back template test status
};

/**
 * @brief Attachment颜色混合状态 | Color mixing state
 */
struct PipelineColorBlendAttachment : public RefBase
{
    bool blendEnable = false;                                  ///< 混合开关 | Hybrid switch
    AMGBlendFactor srcColorBlendFactor = AMGBlendFactor::ONE;  ///< 源color混合因子 | Source color mixing factor
    AMGBlendFactor dstColorBlendFactor = AMGBlendFactor::ZERO; ///< 目标color混合因子 | Target color mixing factor
    AMGBlendFactor srcAlphaBlendFactor = AMGBlendFactor::ONE;  ///< 源alpha混合因子 | Source alpha blending factor
    AMGBlendFactor dstAlphaBlendFactor = AMGBlendFactor::ZERO; ///< 目标alpha混合因子 | Target alpha blending factor
    AMGBlendOp colorBlendOp = AMGBlendOp::ADD;                 ///< color混合模式 | color blending mode
    AMGBlendOp alphaBlendOp = AMGBlendOp::ADD;                 ///< alpha混合模式 | alpha blending mode
    uint32_t colorWriteMask = 0xF;                             ///< 颜色写模版 | Color writing template
};

/**
 * @brief 颜色混合状态 | Color mixing state
 */
struct PipelineColorBlend : public RefBase
{
    std::vector<SharePtr<PipelineColorBlendAttachment>> attachments = {}; ///< Attachment列表 | Attachment list
    Vector4f blendConstants{0.f, 0.f, 0.f, 0.f};                          ///< 混合常数 | Mixing constant
};

/**
 * @brief 渲染状态 | Rendering state
 */
struct PipelineRenderState : public RefBase
{
    SharePtr<PipelineViewport> viewportState = nullptr;           ///< 视口状态 | Viewport state
    SharePtr<PipelineScissor> scissorState = nullptr;             ///< 裁剪状态 | Crop state
    SharePtr<PipelineRasterization> rasterizationState = nullptr; ///< 光栅化状态 | Rasterization state
    SharePtr<PipelineDepthStencil> depthstencilState = nullptr;   ///< 深度模版状态 | In-depth template status
    SharePtr<PipelineColorBlend> colorBlendState = nullptr;       ///< 颜色混合状态 | Color mixing state
    unsigned int dynamicStateMask = 0;                            ///< 动态状态模版 | Dynamic state template
    // SharePtr<PipelineMultisample> multisampleState = nullptr;     ///<多重采样状态 | Multisample state
};

NAMESPACE_AMAZING_ENGINE_END

#endif
