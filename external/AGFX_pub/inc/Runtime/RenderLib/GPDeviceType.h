/**
 * @file GPDeviceType.h
 * @author lishaoyuan (lishaoyuan@bytedance.com)
 * @brief GPDevice Type
 * 1. Capbility&Limit
 * 2. Resource create structure
 * 3. Enum
 * @version 1.0
 * @date 2021-09-01
 * @copyright Copyright (c) 2021 Bytedance Inc. All rights reserved.
 */
#ifndef GPDeviceType_h
#define GPDeviceType_h

// clang-format off
#include <functional>

#include "Gaia/Platform/AMGPlatformDef.h"

#include "Gaia/AMGInclude.h"
#include "Gaia/Image/AMGImageType.h"
#include "Runtime/RenderLib/VertexAttribDesc.h"
#include "Runtime/RenderLib/RendererDeviceTypes.h"
#include "Runtime/RenderLib/PropertyBlock.h"
/**
 * @brief DevTexGetXXX
 * Wrapper for DeviceTexture
 */
#define DevTexGetId(tex) (tex != nullptr ? tex->getId() : nullptr)
#define DevTexGetImageType(tex) (tex->getImageType())
#define DevTexGetPixelFormat(tex) (tex->getPixelFormat())
#define DevTexGetWidth(tex) (tex->getWidth())
#define DevTexGetHeight(tex) (tex->getHeight())
#define DevTexIsTextureYFlip(tex) (tex->isTextureYFlip())
#define DevTexIsRtYFlip(tex) (tex->isRtYFlip())

NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief Executable Task
 * 小任务 | Small task
 */
using Executable=std::function<void()>;
/**
 * @brief 设备能力表 | Equipment Capability Table
 * with device->getCaps() to check device capbility
 */
struct Caps
{
    /**
     * @brief 支持DEPTH16格式 | Support DEPTH16 format
     */
    uint32_t depth16 : 1;                         
    /**
     * @brief 支持STENCIL8格式 | Support STENCIL8 format
     */
    uint32_t stencil8 : 1;                        
    /**
     * @brief 支持DEPTH24格式 | Support DEPTH24 format
     */
    uint32_t depth24 : 1;                         
    /**
     * @brief 支持DEPTH24+STENCIL8格式 | Support DEPTH24+STENCIL8 format
     */
    uint32_t packed_depth24_stencil8 : 1;        
    /**
     * @brief 支持framebuffer_fetch | Support framebuffer_fetch
     */
    uint32_t framebuffer_fetch : 1;               
    /**
     * @brief 支持framebuffer_fetch_depth_stencil | Support framebuffer_fetch_depth_stencil
     */
    uint32_t framebuffer_fetch_depth_stencil : 1; 
    /**
     * @brief 支持pixel_local_storage | Support pixel_local_storage
     */
    uint32_t pixel_local_storage : 1;     
    /**
     * @brief 支持multisampled_render_to_texture | Support multisampled_render_to_texture
     * In Android multisampled_render_to_texture would share MSAA color texture with normal color texture
     */
    uint32_t multisampled_render_to_texture : 1;
    /**
     * @brief 支持fence_sync | Support fence_sync
     * If fence_sync is enabled
     * waitFence is valid
     */
    uint32_t fence_sync : 1;
    /**
     * @brief 支持texture_external | Support texture_external
     * If texture_external is enabled
     * createTexture could use a external image
     */
    uint32_t texture_external : 1;
    /**
     * @brief 支持 texture_rg | Support texture_rg
     * If texture_rg is enabled
     * RGXXXFormat is valid
     */
    uint32_t texture_rg : 1;
     /**
     * @brief 支持 texture_bgra | Support texture_bgra
     * If texture_bgra is enabled
     * BGRAFormat is valid
     */
    uint32_t texture_bgra : 1;
    /**
     * @brief 支持 texture_float | Support texture_float
     * If texture_float is enabled
     * Float PixelFormat(32)is valid
     */
    uint32_t texture_float : 1;
    /**
     * @brief 支持 texture_float_linear | Support texture_float_linear
     * If texture_float_linear is enabled
     * Float PixelFormat(32) with AMGFilterMode::Linear is valid
     */
    uint32_t texture_float_linear : 1;
    /**
     * @brief 支持 texture_half_float | Support texture_half_float
     * If texture_half_float is enabled
     * Half Float PixelFormat(16) is valid
     */
    uint32_t texture_half_float : 1;
    /**
     * @brief 支持 texture_half_float_linear | Support texture_half_float_linear
     * If texture_half_float_linear is enabled
     * Float PixelFormat(16) with AMGFilterMode::Linear is valid
     */
    uint32_t texture_half_float_linear : 1;
    /**
     * @brief 支持 color_buffer_float | Support color_buffer_float
     * If color_buffer_float is enabled
     * Float PixelFormat(32)is valid as a RenderTexture
     */
    uint32_t color_buffer_float : 1;
    /**
     * @brief 支持 color_buffer_half_float | Support color_buffer_half_float
     * If color_buffer_half_float is enabled
     * Float PixelFormat(16)is valid as a RenderTexture
     */
    uint32_t color_buffer_half_float : 1;
    /**
     * @brief 支持 debug_label | Support debug_label
     * If debug_label is enabled
     * AGFX would use debug_label for capture frame
     */
    uint32_t debug_label : 1;
    /**
     * @brief 支持 debug_marker | Support debug_marker
     * If debug_marker is enabled
     * AGFX would use debug_marker for capture frame
     */
    uint32_t debug_marker : 1;
    /**
     * @brief 支持 anisotropy | Support anisotropy
     * If anisotropy is enabled
     * Texture with filter anisotropy is valid
     */
    uint32_t anisotropy : 1;
    /**
     * @brief 支持二进制program | Support binary program
     */
    uint32_t program_binary : 1;
};

/**
 * @brief 设备限制表 | Equipment restriction table
 */
struct Limits
{
    /**
     * @brief a rough estimate of the largest texture
     */
    uint32_t maxTextureSize2D;          ///< 2D纹理最大尺寸 | 2D texture maximum size
    /**
     * @brief the maximum supported texture image units that can be used to access texture maps from the fragment shader
     */
    uint32_t maxTextureUnits;
    /**
     * @brief 顶点着色器最大向量常数数目 | Maximum number of vector constants in the vertex shader
     */
    uint32_t maxVertexUniformVectors;  
    /**
     * @brief 片元着色器最大向量常数数目 | Maximum number of vector constants of the fragment shader
     */
    uint32_t maxFragmentUniformVectors; 
    /**
     * @brief the maximum number of interpolators available for processing varying variables used by vertex and fragment shaders.
     */
    uint32_t maxVaryingVectors;
};

/**
 * @brief 纹理创建参数表（已废弃，请使用tex_create_info） | Texture creation parameter table（Deprecated, please use tex_create_info）
 */
struct texture_create_info 
{
    ImageType imageType = ImageType::INVALID;            
    AMGPixelFormat pixelFormat = AMGPixelFormat::Invalid; 
    int levelCount = 1;                                   
    int width = 0;                                        
    int height = 0;                                      
    int depth = 0;                                        
    int samples = 1;                                      
    int* sizes = nullptr;                              
    union
    {
        const void* const* addrs = nullptr; 
        const void* external;
    };
    bool fixed_location = true;                           
    bool genLevels = false;                                 
    AMGWrapMode u = AMGWrapMode::CLAMP;                    
    AMGWrapMode v = AMGWrapMode::CLAMP;                    
    AMGWrapMode w = AMGWrapMode::CLAMP;                    
    AMGFilterMode mag = AMGFilterMode::NEAREST;            
    AMGFilterMode min = AMGFilterMode::NEAREST;          
    AMGFilterMipmapMode mipmap = AMGFilterMipmapMode::NONE; 
    bool compareEnable = false;                             
    AMGCompareOp compareOp = AMGCompareOp::NEVER;           
    bool textureYFlip = false;                          
    bool rtYFlip = false;
#if AMAZING_DEBUG
    std::string label = "agfx: texture";   ///< for debug / profile
#else
    std::string label;
#endif
};

/**
 * @brief 纹理创建参数表 | Texture creation parameter table
 */
struct tex_create_info
{
    /**
     * @brief image类型 | image type
     */
    ImageType imageType = ImageType::INVALID;             
    /**
     * @brief 像素格式 | Pixel format
     * Only one pixel format
     * There is not the same internal and external difference as OpenGL
     */
    AMGPixelFormat pixelFormat = AMGPixelFormat::Invalid; 
    /**
     * @brief mipmap level数目 | Number of levels
     */
    int levelCount = 1;                                   
    /**
     * @brief 宽度 | width
     */
    int width = 0;                                        
    /**
     * @brief 高度 | height
     */
    int height = 0;                                       
    /**
     * @brief 深度 | depth
     */
    int depth = 0;                                        
    /**
     * @brief 一行跨度 | Line span
     * For alignment purpose
     */
    int pitch = 0;                                        
    /**
     * @brief 采样数 | Number of samples
     */
    int samples = 1;                                      
    /**
     * @brief 每level的数据长度列表 | List of byte sizes for each level
     * Used by addrs data
     */
    int* sizes = nullptr;                                
    union
    {
        /**
         * @brief 每level的数据地址 | Data address of each level
         * addrs[index] is index-th level's image data
         */
        const void* const* addrs = nullptr; 
        /**
         * @brief External image (currently in android)
         */
        const void* external;
    };
    /**
     * @brief 多重采样固定位置开关 | Multiple sampling fixed position switch
     */
    bool fixed_location = true;                             
    /**
     * @brief 自动生成各level | Automatically generate each level
     */
    bool genLevels = false;                
    /**
     * @brief u方向寻址模式 | u direction addressing mode
     */
    AMGWrapMode u = AMGWrapMode::CLAMP;                   
    /**
     * @brief v方向寻址模式 | v direction addressing mode
     */
    AMGWrapMode v = AMGWrapMode::CLAMP;                     
    /**
     * @brief w方向寻址模式 | w direction addressing mode
     */
    AMGWrapMode w = AMGWrapMode::CLAMP;                    
    /**
     * @brief 放大过滤模式 | Zoom filter mode
     */
    AMGFilterMode mag = AMGFilterMode::NEAREST;             
    /**
     * @brief 缩小过滤模式 | Reduce filter mode
     */
    AMGFilterMode min = AMGFilterMode::NEAREST;             
    /**
     * @brief mipmap过滤模式 | mipmap filter mode
     */
    AMGFilterMipmapMode mipmap = AMGFilterMipmapMode::NONE; 
    /**
     * @brief mipmap最小Level | mipmap base level
     */
    int baseLevel = 0;                                      
    /**
     * @brief mipmap最小LOD | mipmap min lod
     */
    float minLod = -1000;                                   
    /**
     * @brief mipmap最大LOD | mipmap max lod
     */
    float maxLod = 1000;                                    
    /**
     * @brief 各向异性采样 | max anisotropy
     */
    int maxAnisotropy = 1;                                  
    /**
     * @brief 纹理比较开关 | Texture comparison switch
     */
    bool compareEnable = false;                             
    /**
     * @brief 纹理比较模式 | Texture comparison mode
     */
    AMGCompareOp compareOp = AMGCompareOp::NEVER;           
    /**
     * @brief 纹理YFlip标记 | Texture YFlip mark
     * Used only with FlipPatch
     */
    bool textureYFlip = false;                              
    /**
     * @brief RTYFlip标记 | RTYFlip mark
     * Used only with FlipPatch
     */
    bool rtYFlip = false;                                   
    /**
     * @brief texture name, for debug / profile
     */
#if AMAZING_DEBUG
    std::string label = "agfx: texture";   ///< for debug / profile
#else
    std::string label;
#endif
    
};


/**
 * @brief 纹理更新参数表 | Texture update parameter table
 */
struct texture_update_info
{
    /**
     * @brief face序号 | face number
     */
    int face = 0;  
    /**
     * @brief level序号 | level number
     */
    int level = 0;  
    /**
     * @brief 窗口起始坐标 | Window start coordinates
     */
    int x = 0;     
    /**
     * @brief 窗口起始纵坐标 | Start ordinate of window
     */
    int y = 0;      
    /**
     * @brief 窗口起始深度坐标 | Window starting depth coordinate
     */
    int z = 0;      
    /**
     * @brief 宽度 | width
     */
    int width = 0;                                        
    /**
     * @brief 高度 | height
     */
    int height = 0;                                       
    /**
     * @brief 深度 | depth
     */
    int depth = 0;                                        
    /**
     * @brief 一行跨度 | Line span
     * For alignment purpose
     */
    int pitch = 0;               
    /**
     * @brief 数据字节数 | Number of data bytes
     */
    int size = 0;   

    union
    {
        /**
         * @brief 每level的数据地址 | Data address of each level
         * addrs[index] is index-th level's image data
         */
        const void* addr = nullptr;
        /**
         * @brief External image (currently in android)
         */
        const void* external;
    };
    /**
     * @brief 自动生成各level | Automatically generate each level
     */
    bool genLevels = false; 
};

/**
 * @brief attachment清除参数 | Clear parameters
 */
struct attachment_clear_info
{
    /**
     * @brief 填充颜色 | Fill color
     */
    float color[4] = {0}; 
    /**
     * @brief 填充深度 | Filling depth
     */
    float depth;          
    /**
     * @brief 填充模版 | Fill the template
     */
    unsigned int stencil; 
};

/**
 * @brief framebuffer清除参数 | Clear parameters
 */
struct framebuffer_clear_info
{
    /**
     * @brief 颜色attachment数 | Color attachment number
     */
    int colorCount = 0;                       
    /**
     * @brief 颜色attachment列表 | Color attachment list
     */
    attachment_clear_info* colors = nullptr;  
    /**
     * @brief 深度attachment | Depth attachment
     */
    attachment_clear_info* depth = nullptr;   
    /**
     * @brief 模版attachment | Template attachment
     */
    attachment_clear_info* stencil = nullptr; 
};

/**
 * @brief 反转模式 | Reverse mode
 * Used in blit/read/drawImage
 */
enum FlipMode
{
    FLIP_NONE = 0x0,
    FLIP_VERTICAL = 0x1,
    FLIP_HORIZONAL = 0x2,
    FLIP_BOTH = 0x3,
};

/**
 * @brief 旋转模式 | Rotation mode
 * Used in blit/read/drawImage
 */
enum RotateMode
{
    ROTATE_CW_0 = 0x0,
    ROTATE_CW_90 = 0x1,
    ROTATE_CW_180 = 0x2,
    ROTATE_CW_270 = 0x3,
};

/**
 * @brief [已废弃] 颜色空间 | [Deprecated] Color space
 * Please use new AMGColorSpace
 */
enum HALColorSpace
{
    HALCOLORSPACE_UNKNOWN = 0x0,
    HALCOLORSPACE_BT601 = 0x1,
    HALCOLORSPACE_BT601_FULL = 0x2,
    HALCOLORSPACE_BT709 = 0x3,
    HALCOLORSPACE_BT709_FULL = 0x4,
    HALCOLORSPACE_BT2020 = 0x5,
    HALCOLORSPACE_BT2020_FULL = 0x6,
};

/**
 * @brief draw image参数表 | Draw image parameters Table
 */
struct image_draw_info
{
    /**
     * @brief 纹理句柄 | Texture handle
     */
    DeviceTexture handle = nullptr;                    ///< 
    /**
     * @brief 读起点横坐标 | Read the abscissa of the starting point
     */
    int srcX = 0;                                      ///< 
    /**
     * @brief 读起点纵坐标 | Read the starting point coordinate
     */
    int srcY = 0;                                      ///< 
    /**
     * @brief 读宽度 | Read width
     */
    int srcWidth = 0;                                  ///< 
    /**
     * @brief 读高度 | Reading height
     */
    int srcHeight = 0;                                 ///< 
    /**
     * @brief 写起点横坐标 | Write start coordinate
     */
    int dstX = 0;                                      ///< 
    /**
     * @brief 写起点纵坐标 | Write starting point coordinate
     */
    int dstY = 0;                                      ///< 
    /**
     * @brief 写宽度，当为0表示取framebuffer的宽度 | Write width, when 0 means the width of framebuffer
     */
    int dstWidth = 0;                                  ///< 
    /**
     * @brief 写高度，当为0表示取framebuffer的高度 | Write height, when 0 means take the height of framebuffer
     */
    int dstHeight = 0;                                 ///< 
    /**
     * @brief 翻转模式 | Flip mode
     */
    FlipMode flipMode = FlipMode::FLIP_NONE;           ///< 
    /**
     * @brief 旋转模式 | Rotation mode
     */
    RotateMode rotateMode = RotateMode::ROTATE_CW_0;   ///< 
    /**
     * @brief 过滤模式 | Filter mode
     */
    AMGFilterMode filterMode = AMGFilterMode::INVALID; ///< 
};

/**
 * @brief 读image参数表 | Read image parameter table
 * If it is not texture 2D, then the srcWidth/Height of the texture should be equivalent to dstWidth/Height
 */
struct image_read_info
{
    /**
     * @brief 纹理句柄 | Texture handle
     */
    DeviceTexture handle = nullptr;                       ///< 
    /**
     * @brief 像素格式 | Pixel format
     */
    AMGPixelFormat pixelFormat = AMGPixelFormat::Invalid; ///< 
    /**
     * @brief face序号 | face number
     */
    int face = 0;  
    /**
     * @brief level序号 | level number
     */
    int level = 0;  
    /**
     * @brief 读起点横坐标 | Read the abscissa of the starting point
     */
    int srcX = 0;                                      ///< 
    /**
     * @brief 读起点纵坐标 | Read the starting point coordinate
     */
    int srcY = 0;                                      ///< 
    /**
     * @brief 读宽度 | Read width
     */
    int srcWidth = 0;                                  ///< 
    /**
     * @brief 读高度 | Reading height
     */
    int srcHeight = 0;                                 ///< 
    /**
     * @brief 写宽度，当为0表示取framebuffer的宽度 | Write width, when 0 means the width of framebuffer
     */
    int dstWidth = 0;                                  ///< 
    /**
     * @brief 写高度，当为0表示取framebuffer的高度 | Write height, when 0 means take the height of framebuffer
     */
    int dstHeight = 0;                                 ///< 
    /**
     * @brief 翻转模式 | Flip mode
     */
    FlipMode flipMode = FlipMode::FLIP_NONE;           ///< 
    /**
     * @brief 旋转模式 | Rotation mode
     */
    RotateMode rotateMode = RotateMode::ROTATE_CW_0;   ///< 
    /**
     * @brief 过滤模式 | Filter mode
     */
    AMGFilterMode filterMode = AMGFilterMode::INVALID; ///< 
    void* data = nullptr;                                 ///< 数据地址 | Data address
};

/**
 * @brief blit image参数表 | Parameters Table
 */
struct image_blit_info
{
    /**
     * @brief 读纹理句柄 | Read texture handle
     */
    DeviceTexture src = nullptr;                       ///< 
    /**
     * @brief 写纹理句柄 | Write texture handle
     */
    DeviceTexture dst = nullptr;                       ///< 
    /**
     * @brief 读起点横坐标 | Read the abscissa of the starting point
     */
    int srcX = 0;                                      ///< 
    /**
     * @brief 读起点纵坐标 | Read the starting point coordinate
     */
    int srcY = 0;                                      ///< 
    /**
     * @brief 读宽度 | Read width
     */
    int srcWidth = 0;                                  ///< 
    /**
     * @brief 读高度 | Reading height
     */
    int srcHeight = 0;                                 ///< 
    /**
     * @brief 写起点横坐标 | Write start coordinate
     */
    int dstX = 0;                                      ///< 
    /**
     * @brief 写起点纵坐标 | Write starting point coordinate
     */
    int dstY = 0;                                      ///< 
    /**
     * @brief 写宽度，当为0表示取framebuffer的宽度 | Write width, when 0 means the width of framebuffer
     */
    int dstWidth = 0;                                  ///< 
    /**
     * @brief 写高度，当为0表示取framebuffer的高度 | Write height, when 0 means take the height of framebuffer
     */
    int dstHeight = 0;                                 ///< 
    /**
     * @brief 翻转模式 | Flip mode
     */
    FlipMode flipMode = FlipMode::FLIP_NONE;           ///< 
    /**
     * @brief 旋转模式 | Rotation mode
     */
    RotateMode rotateMode = RotateMode::ROTATE_CW_0;   ///< 
    /**
     * @brief 过滤模式 | Filter mode
     */
    AMGFilterMode filterMode = AMGFilterMode::INVALID; ///< 
};

/**
 * @brief [已废弃] image裸数据参数 | [Deprecated] Raw data parameters
 * Not used by external API
 */
struct image_raw_data_info
{
    AMGPixelFormat format = AMGPixelFormat::Invalid;                 ///< 像素格式 | Pixel format
    HALColorSpace colorSpace = HALColorSpace::HALCOLORSPACE_UNKNOWN; ///< 颜色空间 | Color space
    int rowStrideY = 0;                                              ///< Y平面行跨度 | Y-plane row span
    int pixelStrideY = 0;                                            ///< Y平面像素跨度 | Y-plane pixel span
    const void* dataY = nullptr;                                     ///< Y平面数据地址 | Y plane data address
    int rowStrideU = 0;                                              ///< U平面行跨度 | U-plane row span
    int pixelStrideU = 0;                                            ///< U平面像素跨度 | U plane pixel span
    const void* dataU = nullptr;                                     ///< U平面数据地址 | U plane data address
    int rowStrideV = 0;                                              ///< V平面行跨度 | V-plane row span
    int pixelStrideV = 0;                                            ///< V平面像素跨度 | V-plane pixel span
    const void* dataV = nullptr;                                     ///< V平面数据地址 | V plane data address
};

/**
 * @brief 纹理转换参数表 | Texture conversion parameter table
 */
struct texture_convert_info
{
    int srcX = 0;                                            ///< 读起点横坐标 | Read the abscissa of the starting point
    int srcY = 0;                                            ///< 读起点纵坐标 | Read the starting point ordinate
    int srcWidth = 0;                                        ///< 读宽度 | Read width
    int srcHeight = 0;                                       ///< 读高度 | Reading height
    AMGPixelFormat dstPixelFormat = AMGPixelFormat::Invalid; ///< 写像素格式 | Write pixel format
    int dstWidth = 0;                                        ///< 写宽度 | Write width
    int dstHeight = 0;                                       ///< 写高度 | Write height
    AMGWrapMode dstWrapMode = AMGWrapMode::CLAMP;            ///< 写寻址模式 | Write addressing mode
    AMGFilterMode dstFilterMode = AMGFilterMode::NEAREST;    ///< 写过滤模式 | Write filter mode
    FlipMode flipMode = FlipMode::FLIP_NONE;                 ///< 翻转模式 | Flip mode
    RotateMode rotateMode = RotateMode::ROTATE_CW_0;         ///< 旋转模式 | Rotation mode
    const image_raw_data_info* rawDataInfo = nullptr;        ///< 裸数据信息 | Bare data information
#if AMAZING_DEBUG
    std::string label = "agfx: texture(converted)";   ///< for debug / profile
#else
    std::string label;
#endif
};

/**
 * @brief 由系统原生缓存创建纹理参数表 | Create texture parameter table from system native cache
 */
struct texture_from_nativeBuffer_create_info
{
    NativeBuffer nativeBuffer = nullptr;       ///< 系统原生缓存句柄 | System native cache handle
    AMGWrapMode u = AMGWrapMode::CLAMP;        ///< u方向寻址模式 | u direction addressing mode
    AMGWrapMode v = AMGWrapMode::CLAMP;        ///< v方向寻址模式 | v direction addressing mode
    AMGFilterMode mag = AMGFilterMode::LINEAR; ///< 放大过滤模式 | Zoom filter mode
    AMGFilterMode min = AMGFilterMode::LINEAR; ///< 缩小过滤模式 | Reduce filter mode
    bool internal = false;                     ///< 是否内部纹理 | Internal texture
    bool textureYFlip = false;                 ///< 作为纹理是否上下翻转 | Whether to flip up and down as a texture
    bool rtYFlip = false;                      ///< 作为RT是否上下翻转 | Whether to flip up and down as RT
    bool rbFlip = false;                       ///< RB通道是否翻转 | Whether the RB channel is flipped
    DeviceTexture outputTexture = nullptr;     ///< overwrite existing texture
#if AMAZING_DEBUG
    std::string label = "agfx: texture(native buffer)";   ///< for debug / profile
#else
    std::string label;
#endif
    size_t plane = 0u;
#if AMAZING_PLATFORM == AMAZING_MACOS
    bool mapping = false; // map CVPixelBuffer to OpenGL GL_TEXTURE_RECTANGLE, which cannot be sampled normally
#endif
};

#if AGFX_RAY_TRACING
enum IntersectionType
{
    INTERSECTION_NEAREST = 0,
    INTERSECTION_ANY = 1,
};

enum IntersectionDataType
{
    INTERSECTION_DATA_DISTANCE = 0,
    INTERSECTION_DATA_DISTANCE_PRIMITIVE_INDEX = 1,
    INTERSECTION_DATA_DISTANCE_PRIMITIVE_INDEX_COORDINATES = 2,
    INTERSECTION_DATA_DISTANCE_PRIMITIVE_INDEX_INSTANCE_INDEX = 3,
    INTERSECTION_DATA_DISTANCE_PRIMITIVE_INDEX_INSTANCE_INDEX_COORDINATES = 4,
    
};

struct intersect_info
{
    IntersectionType intersectionType = INTERSECTION_ANY;
    IntersectionDataType intersectionDataType = INTERSECTION_DATA_DISTANCE;
    Intersector intersector;
    AccelerationStructure accelerationStructure;
    DeviceBuffer rayBuffer;
    DeviceBuffer intersectionBuffer;
    uint64_t rayCount;
};
#endif

NAMESPACE_AMAZING_ENGINE_END

// clang-format on
#endif /* GPDeviceType_h */
