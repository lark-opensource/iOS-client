/**
 * @file RendererDeviceTypes.h
 * @author Andrew Wu (andrew.wu@bytedance.com)
 * @brief 渲染设备数据类型定义 | Rendering device data type definition
 * @version 1.0.0
 * @date 2019-11-13
 * @copyright Copyright (c) 2019 Bytedance Inc. All rights reserved.
 */
#pragma once

#include <assert.h>

#include "Gaia/AMGInclude.h"
#include "Gaia/Image/AMGImageType.h"
#include "Gaia/Platform/AMGPlatformDef.h"
#include "Runtime/RenderLib/PipelineState.h"
#include "Runtime/RenderLib/MaterialType.h"
#include "Runtime/RenderLib/VertexAttribDesc.h"
#include "Gaia/AMGSharePtr.h"

/// 系统原生窗口句柄 | System native window handle
typedef void* NativeWindow;
/// 系统原生缓存句柄 | System native cache handle
typedef void* NativeBuffer;

NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief 渲染设备类型 | Rendering device type
 */
enum class RendererType
{
    Null,       //!< No rendering.
    Direct3D9,  //!< Direct3D 9.0
    Direct3D10, //!< Direct3D 10.0
    Direct3D11, //!< Direct3D 11.0
    Direct3D12, //!< Direct3D 12.0
    Gnm,        //!< GNM
    Metal,      //!< Metal
    OpenGLES2,  //!< OpenGL ES 2.0
    OpenGLES30, //!< OpenGL ES 3.0
    OpenGLES31, //!< OpenGL ES 3.1
    OpenGLES32, //!< OpenGL ES 3.2
    OpenGL,     //!< OpenGL 2.1+
    Vulkan,     //!< Vulkan
    OpenCL,     //!<OpenCL
    Count
};
/**
 * @brief 渲染Context类型 | Rendering context type
 */
enum class ContextBindType
{
    SHARE_CONTEXT_0 = 0,
    SHARE_CONTEXT_1,
    SHARE_CONTEXT_2,
    SHARE_CONTEXT_3,
    MAX_CONTEXT_NUM,
    SHARE_CONTEXT = 9998,
    MAIN_CONTEXT = 9999,
};
constexpr const char* rendererTypeToStr(const RendererType& rendererType)
{
    switch (rendererType)
    {
        case RendererType::Direct3D9:
            return "Direct3D9";
        case RendererType::Direct3D10:
            return "Direct3D10";
        case RendererType::Direct3D11:
            return "Direct3D11";
        case RendererType::Direct3D12:
            return "Direct3D12";
        case RendererType::Gnm:
            return "Gnm";
        case RendererType::Metal:
            return "Metal";
        case RendererType::OpenGLES2:
            return "OpenGLES2";
        case RendererType::OpenGLES30:
            return "OpenGLES30";
        case RendererType::OpenGLES31:
            return "OpenGLES31";
        case RendererType::OpenGLES32:
            return "OpenGLES32";
        case RendererType::OpenGL:
            return "OpenGL";
        case RendererType::Vulkan:
            return "Vulkan";
        case RendererType::OpenCL:
            return "OpenCL";
        default:
            return "Null";
    }
}
class GPDevice;
NAMESPACE_AMAZING_ENGINE_END

template <typename T>
struct DeviceWrapper;
/**
 * @brief DeviceHandle 
 * Handle type for native type
 * @tparam T native type
 */

template <typename T>
struct DeviceHandle
{
    DeviceHandle() = default;
    DeviceHandle(const DeviceHandle<T>& other) = default;
    DeviceHandle<T>& operator=(const DeviceHandle<T>& other) = default;
    DeviceHandle(DeviceHandle<T>&& other) = default;
    DeviceHandle<T>& operator=(DeviceHandle<T>&& other) = default;
    DeviceHandle(const T* handle)
        : handle((DeviceWrapper<T>*)handle)
    {
    }

    DeviceHandle<T>& operator=(T* handle)
    {
        this->handle = (DeviceWrapper<T>*)handle;
        return *this;
    }

    DeviceWrapper<T>* operator->() const
    {
        return handle;
    }

    template <typename U, typename = typename std::enable_if_t<std::is_base_of<T, U>::value>>
    explicit operator U*() const
    {
        return (U*)(T*)handle;
    }

    explicit operator bool() const
    {
        return nullptr != handle;
    }
    bool operator!() const
    {
        return nullptr == handle;
    }
    friend bool operator==(std::nullptr_t, const DeviceHandle<T>& other)
    {
        return nullptr == other.handle;
    }
    friend bool operator!=(std::nullptr_t, const DeviceHandle<T>& other)
    {
        return nullptr != other.handle;
    }

protected:
    DeviceWrapper<T>* handle = nullptr;
};

struct TextureBase;

template <>
struct AMAZING_EXPORT DeviceWrapper<TextureBase>
{
    void operator delete(void*);
    void operator delete[](void*);
    DeviceWrapper<TextureBase>() = delete;
    ~DeviceWrapper<TextureBase>();
    void* getId();
    int getWidth();
    int getHeight();
    int getDepth();
    AmazingEngine::ImageType getImageType();
    AmazingEngine::AMGPixelFormat getPixelFormat();
    bool isTextureYFlip();
    bool isRtYFlip();
    NativeBuffer getNativeBuffer();
    AmazingEngine::RendererType getRendererType();
    AmazingEngine::GPDevice* getGPDevice();
    AmazingEngine::AMGWrapMode getWrapModeU();
    AmazingEngine::AMGWrapMode getWrapModeV();
    AmazingEngine::AMGWrapMode getWrapModeW();
    AmazingEngine::AMGFilterMode getFilterModeMag();
    AmazingEngine::AMGFilterMode getFilterModeMin();
    AmazingEngine::AMGFilterMipmapMode getFilterModeMip();
};

struct AMAZING_EXPORT DeviceTexture : public DeviceHandle<TextureBase>
{
    DeviceTexture() = default;

    DeviceTexture(TextureBase* handle);

    DeviceTexture(const DeviceTexture& other)
    {
        operator=(other);
    }

    DeviceTexture& operator=(TextureBase* handle);

    explicit operator int64_t() const
    {
        return (int64_t)handle;
    }

    DeviceTexture& operator=(const DeviceTexture& other)
    {
        if (this != &other)
        {
            this->handle = other.handle;
            this->signature = other.signature;
        }
        return *this;
    }

    bool operator==(const DeviceTexture& other) const
    {
        return other.signature == this->signature && other.handle == this->handle;
    }

    bool operator!=(const DeviceTexture& other) const
    {
        return !this->operator==(other);
    }

    bool operator==(std::nullptr_t) const
    {
        return this->handle == nullptr && this->signature == 0;
    }

    bool operator!=(std::nullptr_t) const
    {
        return !this->operator==(nullptr);
    }

private:
    size_t signature = 0;
};

#define HANDLE_OBJECT(object) handle_##object##_t

#define DEFINE_HANDLE(object) typedef struct HANDLE_OBJECT(object) * object;

DEFINE_HANDLE(DeviceWindow);
/// 缓存句柄 | Cache handle
DEFINE_HANDLE(DeviceBuffer);
/// 帧句柄 | Frame handle
DEFINE_HANDLE(DeviceFramebuffer);
/// 渲染序列句柄 | Render sequence handle
DEFINE_HANDLE(DeviceSequence);
/// 同步句柄 | Fence handle
DEFINE_HANDLE(DeviceFence);

NAMESPACE_AMAZING_ENGINE_BEGIN
/// 着色器句柄 | Shader handle
DEFINE_HANDLE(DeviceShader);
/// 渲染管线句柄 | Render pipeline handle
DEFINE_HANDLE(RenderPipeline);
/// 计算管线句柄 | Compute pipeline handle
DEFINE_HANDLE(ComputePipeline);
/// 渲染实体句柄 | Render entity handle
DEFINE_HANDLE(RenderEntity);
/// 计算实体句柄 | Compute entity handle
DEFINE_HANDLE(ComputeEntity);

#if AGFX_RAY_TRACING
DEFINE_HANDLE(Intersector);
DEFINE_HANDLE(AccelerationStructure);
#endif
DEFINE_HANDLE(NativeSurface);

/**
 * @brief 符号类型 | Symbol type
 */
enum class SymbolType
{
    INVALID = 0,
    /**
     * @brief Pure Native Type
     */
    BOOL = 10,
    BOOL_VEC2,
    BOOL_VEC3,
    BOOL_VEC4,
    UNSIGNED_INT,
    UNSIGNED_INT_VEC2,
    UNSIGNED_INT_VEC3,
    UNSIGNED_INT_VEC4,
    INT,
    INT_VEC2,
    INT_VEC3,
    INT_VEC4,
    FLOAT,
    FLOAT_VEC2,
    FLOAT_VEC3,
    FLOAT_VEC4,
    FLOAT_MAT2,
    FLOAT_MAT3,
    FLOAT_MAT4,
    FLOAT_MAT2x3,
    FLOAT_MAT3x2,
    FLOAT_MAT2x4,
    FLOAT_MAT4x2,
    FLOAT_MAT3x4,
    FLOAT_MAT4x3,
    HALF,
    HALF_VEC2,
    HALF_VEC3,
    HALF_VEC4,
    HALF_MAT2,
    HALF_MAT3,
    HALF_MAT4,
    HALF_MAT2x3,
    HALF_MAT3x2,
    HALF_MAT2x4,
    HALF_MAT4x2,
    HALF_MAT3x4,
    HALF_MAT4x3,
    FLOAT_MAT4_TRANSPOSE, // Currently only works on Windows Angle

    SAMPLER_START = 100,
    /**
     * @brief Texture Sampler Type
     */
    UNSIGNED_INT_SAMPLER_1D = SAMPLER_START,
    UNSIGNED_INT_SAMPLER_2D,
    UNSIGNED_INT_SAMPLER_3D,
    UNSIGNED_INT_SAMPLER_CUBE,
    UNSIGNED_INT_SAMPLER_RECT,
    UNSIGNED_INT_SAMPLER_BUFFER,
    UNSIGNED_INT_SAMPLER_2D_MS,
    UNSIGNED_INT_SAMPLER_1D_ARRAY,
    UNSIGNED_INT_SAMPLER_2D_ARRAY,
    UNSIGNED_INT_SAMPLER_CUBE_ARRAY,
    UNSIGNED_INT_SAMPLER_2D_MS_ARRAY,
    INT_SAMPLER_1D,
    INT_SAMPLER_2D,
    INT_SAMPLER_3D,
    INT_SAMPLER_CUBE,
    INT_SAMPLER_RECT,
    INT_SAMPLER_BUFFER,
    INT_SAMPLER_2D_MS,
    INT_SAMPLER_1D_ARRAY,
    INT_SAMPLER_2D_ARRAY,
    INT_SAMPLER_CUBE_ARRAY,
    INT_SAMPLER_2D_MS_ARRAY,
    SAMPLER_1D,
    SAMPLER_2D,
    SAMPLER_3D,
    SAMPLER_CUBE,
    SAMPLER_RECT,
    SAMPLER_BUFFER,
    SAMPLER_2D_MS,
    SAMPLER_1D_ARRAY,
    SAMPLER_2D_ARRAY,
    SAMPLER_CUBE_ARRAY,
    SAMPLER_2D_MS_ARRAY,

    SAMPLER_1D_SHADOW,
    SAMPLER_2D_SHADOW,
    SAMPLER_CUBE_SHADOW,
    SAMPLER_RECT_SHADOW,
    SAMPLER_1D_ARRAY_SHADOW,
    SAMPLER_2D_ARRAY_SHADOW,
    SAMPLER_CUBE_ARRAY_SHADOW,

    SAMPLER_EXTERNAL,

    IMAGE_START = 150,
    /**
     * @brief Texture Image Type
     */
    UNSIGNED_INT_IMAGE_1D = IMAGE_START,
    UNSIGNED_INT_IMAGE_2D,
    UNSIGNED_INT_IMAGE_3D,
    UNSIGNED_INT_IMAGE_CUBE,
    UNSIGNED_INT_IMAGE_RECT,
    UNSIGNED_INT_IMAGE_BUFFER,
    UNSIGNED_INT_IMAGE_2D_MS,
    UNSIGNED_INT_IMAGE_1D_ARRAY,
    UNSIGNED_INT_IMAGE_2D_ARRAY,
    UNSIGNED_INT_IMAGE_CUBE_ARRAY,
    UNSIGNED_INT_IMAGE_2D_MS_ARRAY,
    INT_IMAGE_1D,
    INT_IMAGE_2D,
    INT_IMAGE_3D,
    INT_IMAGE_CUBE,
    INT_IMAGE_RECT,
    INT_IMAGE_BUFFER,
    INT_IMAGE_2D_MS,
    INT_IMAGE_1D_ARRAY,
    INT_IMAGE_2D_ARRAY,
    INT_IMAGE_CUBE_ARRAY,
    INT_IMAGE_2D_MS_ARRAY,
    IMAGE_1D,
    IMAGE_2D,
    IMAGE_3D,
    IMAGE_CUBE,
    IMAGE_RECT,
    IMAGE_BUFFER,
    IMAGE_2D_MS,
    IMAGE_1D_ARRAY,
    IMAGE_2D_ARRAY,
    IMAGE_CUBE_ARRAY,
    IMAGE_2D_MS_ARRAY,
    /**
     * @brief Uniform Block Type
     */
    UNIFORM_BLOCK = 200,
    COUNTER_BLOCK,
    /**
     * @brief Shader Storage Type
     */
    STORAGE_BLOCK,
    SYMBOL_IGNORE = 999,
};

/**
 * @brief 属性 | Attributes
 */
class AMAZING_EXPORT DeviceProperty : public RefBase
{
public:
    /**
     * @brief constructor
     * @param name name
     * @param symbolType symbol type 
     * @param count data count
     * @param src value 
     * @param userData user data 
     */
    DeviceProperty(const char* name, SymbolType symbolType, int count, const void* src = nullptr, bool copyData = true);

    /**
     * @brief constructor
     * @param name name
     * @param symbolType symbol typer 
     * @param count data count
     * @param enumKey enumKey
     * @param src data
     * @param userData user data
     */
    DeviceProperty(const char* name, SymbolType symbolType, int count, int enumKey, const void* src = nullptr, bool copyData = true);

    /**
     * @brief constructor
     * @param symbolType symbol typer
     * @param count data count
     * @param src data
     * @param userData user data
     */
    DeviceProperty(SymbolType symbolType, int count, const void* src = nullptr, bool copyData = true);

    /**
     * @brief copy constructor
     * @param property the other DeviceProperty
     */
    DeviceProperty(const DeviceProperty& property);
    /**
     * @brief copy assignment operator
     * @param property the other DeviceProperty
     */
    DeviceProperty& operator=(const DeviceProperty& property) = delete;
    /**
     * @brief destructor
     */
    virtual ~DeviceProperty();

    /**
     * @brief get float value
     * @return float* 
     */
    const float* asFloat() const
    {
        if (symbolType == SymbolType::FLOAT)
        {
            return static_cast<const float*>(pointer);
        }

        return nullptr;
    }
    /**
     * @brief get vec4 value
     * @return Vector4f* 
     */
    const Vector4f* asVec4() const
    {
        if (symbolType == SymbolType::FLOAT_VEC4)
        {
            return static_cast<const Vector4f*>(pointer);
        }
        return nullptr;
    }
    /**
     * @brief get vec3 value
     * @return Vector3f* 
     */
    const Vector3f* asVec3() const
    {
        if (symbolType == SymbolType::FLOAT_VEC3)
        {
            return static_cast<const Vector3f*>(pointer);
        }
        return nullptr;
    }
    /**
     * @brief get vec2 value
     * @return Vector2f* 
     */
    const Vector2f* asVec2() const
    {
        if (symbolType == SymbolType::FLOAT_VEC2)
        {
            return static_cast<const Vector2f*>(pointer);
        }
        return nullptr;
    }

    /**
     * @brief get matrix4x4 value
     * @return Matrix4x4f* 
     */
    const Matrix4x4f* asMat4() const
    {
        if (symbolType == SymbolType::FLOAT_MAT4 || symbolType == SymbolType::FLOAT_MAT4_TRANSPOSE)
        {
            return static_cast<const Matrix4x4f*>(pointer);
        }
        return nullptr;
    }
    /**
     * @brief get int value
     * @return int* 
     */
    const int* asInt() const
    {
        if (symbolType == SymbolType::INT)
        {
            return static_cast<const int*>(pointer);
        }
        return nullptr;
    }

    /**
     * @brief get user data
     * @return void* 
     */
    void* asUserData()
    {
        return userData;
    }

    /**
     * @brief set user data
     * @param userData pointer to user data
     */
    void setUserData(void* inputUserData)
    {
        userData = inputUserData;
    }

    /**
     * @brief set value
     * @param src pointer to data
     */
    void setValue(const void* src);

    /**
     * @brief set pointer
     * @param src pointer to data
     */
    void setPointer(const void* src);

    /**
     * @brief reset data count
     * @param newCount data count
     */
    void resetCount(int newCount)
    {
        if (count != newCount)
        {
            count = newCount;
            memDirty = true;
        }
    }

    /**
     * @brief reset symbol type
     * @param type symbol type
     */
    void resetType(SymbolType type)
    {
        if (symbolType != type)
        {
            symbolType = type;
            memDirty = true;
        }
    }

    /**
     * @brief reset eunmKey
     * @param key enumKey
     */
    void resetEnumKey(int key)
    {
        enumKey = key;
    }
    /**
     * @brief get eunmKey
     * @return int enumKey
     */
    int getEnumKey() const
    {
        return enumKey;
    }

    /**
     * @brief get symbol type
     * @return const SymbolType symbol type
     */
    const SymbolType& getType() const
    {
        return symbolType;
    }

    /**
     * @brief force set dirty
     * @param forceDirty dirty
     */
    void forceSetDirty(bool forceDirty)
    {
        dirty = forceDirty;
    }
    /**
     * @brief get is dirty
     * @return bool dirty
     */
    bool isDirty() const
    {
        return dirty;
    }
    /**
     * @brief get pointer to data
     * @return const void* pointer to data
     */
    const void* getPointer() const
    {
        return pointer;
    }

    /**
     * @brief get name
     * @return const char* name
     */
    const char* getName() const
    {
        return name;
    }
    /**
     * @brief get data count
     * @return const int data count 
     */
    const int& getCount() const
    {
        return count;
    }

protected:
    void copyName(const char* curName);
    void allocatePropertyMemory();

    SymbolType symbolType = SymbolType::INVALID; // 属性类型 | Attribute type
    char* name = nullptr;                        // 属性名 | Attribute name
    int count = 0;                               // 属性值数目 | Number of attribute values
    void* pointer = nullptr;                     // 属性值地址 | Attribute value address
    void* userData = nullptr;                    // 上层的userData | Upper userData
    int enumKey = -1;                            // enum值 | enum value
    int memSize = 0;                             // 当前保存数据占据的内存大小 | The memory size occupied by the current saved data
    bool dirty = true;                           // 当前的pointer中的值是否dirty | Whether the value in the current pointer is dirty
    bool memDirty = false;                       // 当前的内存是否需要重新申请 | Does the current memory need to be re-applied
    bool saveData = false;                       // 是否保存数据 | Whether to save data
};

/**
 * @brief 材质属性类型 | Material attribute type
 */
enum class MaterialPropertyType
{
    FLOAT,
    VEC4,
    TEX,
    MULTI,
};

/**
 * @brief 图元类型 | Primitive type
 */
enum class AMGPrimitive
{
    POINTS,
    LINES,
    /**
     * @brief [Deprecated] only supported in OpenGLES Backend
     */
    LINE_LOOP,
    LINE_STRIP,
    TRIANGLES,
    TRIANGLE_STRIP,
    TRIANGLE_FAN,
    UNKOWN
};

/**
 * @brief 多重采样模式 | Multiple sampling mode
 * _4X means that sample count 4
 * _2X and _8X is lacking
 */
enum class AMGMSAAMode
{
    NONE = 0,
    _2X = 1,
    _4X = 2,
    _8X = 3,
    _16X = 4,
    COUNT = 5,
};
constexpr unsigned int getMSAASamples(const AMGMSAAMode msaaMode)
{
    switch (msaaMode)
    {
        case AMGMSAAMode::NONE:
            return 1;
        case AMGMSAAMode::_2X:
            return 2;
        case AMGMSAAMode::_4X:
            return 4;
        case AMGMSAAMode::_8X:
            return 8;
        case AMGMSAAMode::_16X:
            return 16;
        default:
            return 1;
    }
}

/**
 * @brief 渲染目标的Attachment描述 | Attachment description of the render target
 */
struct AttachmentDesc
{
public:
    DeviceTexture handle = nullptr; ///< 纹理句柄 | Texture handle
    int face = 0;                   ///< 纹理里image所在的face | The face where the image is in the texture
    int level = 0;                  ///< 纹理里image所在的level | The level of the image in the texture
    int layer = 0;                  ///< 纹理里image所在的layer | The layer where the image in the texture is located
};

/**
 * @brief 渲染目标描述 | Render target description
 */
struct RenderTargetDesc
{
public:
    AMGMSAAMode samples = AMGMSAAMode::NONE; ///< 每像素采样数 | Number of samples per pixel
    unsigned int colorCount = 0;             ///< 颜色缓存数 | Number of color buffers
    AttachmentDesc* colors = nullptr;        ///< 颜色缓存列表 | Color cache list
    AttachmentDesc* depth = nullptr;         ///< 深度缓存 | Depth buffer
    AttachmentDesc* stencil = nullptr;       ///< 模版缓存 | Template cache
#if AMAZING_DEBUG
    std::string label = "agfx: frame buffer"; ///< for debug / profile
#else
    std::string label;
#endif
};
/**
 * @brief 着色器描述 | Shader description
 */
struct ShaderDesc
{
    AMGShaderType m_type = AMGShaderType::NONE; ///< 着色器类型 | Shader type
    const void* m_buff = nullptr;               ///< 着色器文本地址 | Shader text address
    int32_t m_size = 0;                         ///< 着色器文本大小 | Shader text size
#if AMAZING_DEBUG
    std::string label = "agfx: shader"; ///< for debug / profile
#else
    std::string label;
#endif
};

/**
 * @brief 输入属性描述 | Enter attribute description
 */
struct InputAttribDesc
{
    std::string name = "";                                        ///< 输入属性名 | Enter the attribute name
    AMGVertexAttribType attribType = AMGVertexAttribType::UNKOWN; ///< 输入属性类型 | Input attribute type
    int index = 0;                                                ///< 输入属性序号 | Enter the attribute number
    int size = 0;                                                 ///< 输入属性分量数 | Enter the number of attribute components
    AMGDataType type = AMGDataType::Invalid;                      ///< 输入属性数据类型 | Input attribute data type
    int32_t offset = 0;                                           ///< 输入属性偏移 | Input attribute offset
};

/**
 * @brief 输入绑定描述 | Enter binding description
 */
struct InputBindingDesc
{
    DeviceBuffer vertex_buffer = 0; ///< 输入缓存句柄 | Input cache handle
    int divisor = 0;                ///< 输入数据每批数目 | Enter the number of data per batch
    int stride = 0;                 ///< 输入数据跨度长度 | Input data span length
    const void* pointer = nullptr;  ///< 输入数据偏移或者地址 | Enter data offset or address
};

/**
 * @brief 几何描述 | Geometric description
 */
struct GeometryDesc
{
    std::vector<InputAttribDesc> inputAttribs = {};   ///< 输入属性列表 | Input attribute list
    std::vector<InputBindingDesc> inputBindings = {}; ///< 输入绑定列表 | Enter binding list
    DeviceBuffer index_buffer = 0;                    ///< 索引缓存句柄 | Index cache handle
    AMGDataType type = AMGDataType::Invalid;          ///< 索引数据类型 | Index data type
    const void* indices = nullptr;                    ///< 索引数据偏移或者地址 | Index data offset or address
    AMGPrimitive mode = AMGPrimitive::TRIANGLES;      ///< 图元类型 | Primitive type
    int vertexBase = 0;                               ///< 顶点基数 | Vertex cardinality
    int indexBase = 0;                                ///< 索引基数 | Index cardinality
    int instanceBase = 0;                             ///< 实例基数 | Instance cardinality
    int vertexCount = 0;                              ///< 顶点数目 | Number of vertices
    int indexCount = 0;                               ///< 索引数目 | Number of indexes
    int instanceCount = 0;                            ///< 实例数目 | Number of instances
    DeviceBuffer indirect_buffer = 0;                 ///< 间接渲染缓存句柄 | Indirect rendering cache handle
    const void* indirect = 0;                         ///< 间接渲染数据偏移或者地址 | Indirect rendering data offset or address
    int countDraw = 0;                                ///< 多绘制数目 | Multi-draw number
    int countDrawMax = 0;                             ///< 多绘制数目最大值 | Maximum number of multiple draws
    int strideDraw = 0;                               ///< 多绘制参数跨度长度 | Multi-drawing parameter span length
#if AMAZING_DEBUG
    std::string label = "agfx: geometry"; ///< for debug / profile
#else
    std::string label;
#endif
};

/**
 * @brief [Deprecated]渲染流程 | Render Pass
 */
struct RenderPass
{
    RenderPipeline m_pipeline = 0; ///< 渲染管线句柄 | Render pipeline handle
    //    const RenderState* m_renderState = nullptr;
    SharePtr<PipelineRenderState> m_renderState = nullptr; ///< 渲染状态 | Rendering state
    // instance
    //const RenderTargetDesc* m_renderTarget = nullptr;
    const std::unordered_map<int, SharePtr<DeviceProperty>>* m_materialPropertiesMap = nullptr; ///< 渲染属性地址 | Rendering attribute address
    const DeviceProperty* m_materialProperties = nullptr;                                       ///< 渲染属性地址 | Rendering attribute address
    int32_t m_propCount = 0;                                                                    ///< 渲染属性数目 | Number of rendering attributes
};

/**
 * @brief [Deprecated] Shader 编译类型
 */
enum class ShaderCompiler
{
    ES20,
    ES30,
    METAL,
    VULKAN
};
/**
 * @brief 状态属性 // State Type
 * sync/push/resetState in OpenGLES Backend
 */
enum StateBit
{
    /**
     * @brief Test&Mode Enabled such as depth/stencil/cull/...
     */
    ENABLE = 0x00000001,
    /**
     * @brief ViewPort State
     */
    VIEWPORT = 0x00000002,
    /**
     * @brief Scissor State
     */
    SCISSOR = 0x00000004,
    /**
     * @brief Rasterize State
     */
    RASTERIZER = 0x00000008,
    /**
     * @brief [Deprecated] State
     */
    MULTISAMPLE = 0x00000010,
    /**
     * @brief Depth&Stencil Mode State
     */
    DEPTH_STENCIL = 0x00000020,
    /**
     * @brief Blend Constant Color State
     */
    GENERAL_BLEND = 0x00000040,
    /**
     * @brief Array Buffer Binding State
     */
    ARRAY_BINDING = 0x00000080,
    /**
     * @brief Texture Binding State
     */
    TEXTURE_BINDING = 0x00000100,
    /**
     * @brief RenderBuffer Binding State
     */
    RENDERBUFFER_BINDING = 0x00000200,
    /**
     * @brief FrameBuffer Binding State
     */
    FRAMEBUFFER_BINDING = 0x00000400,
    /**
     * @brief VAO Binding State
     */
    VERTEXATTRIB_ENABLED = 0x00000800,
    /**
     * @brief Buffer Binding State
     */
    BUFFER_BINDING = 0x00001000,
    /**
     * @brief Program Binding State
     */
    PROGRAM_BINDING = 0x00002000,
    /**
     * @brief Internal CPU State 
     * It does not influence GL states
     * It only reset device's member state 
     * PS: device would use own state for dirty check 
     * For Example:
     * STUB_LOGGER(glBindBuffer(XXX))
     * STUB_LOGGER(glBindBuffer(XXX))
     * The second glBindBuffer maybe not a really gl call because of dirty-check
     * Sometimes dirty-check would be wrong becuase of cross rendering between AGFX-Pure GL So resetState is neccesary
     */
    RESET_STATE_MASK = 0x00004000,
    GENERAL_STATE_MASK = 0x0000FFFF,
    /**
     * @brief Blend Mode State for attachment 0
     */
    ATTACHMENT0_BLEND = 0x00010000,
    /**
     * @brief Blend Mode State for all attachments
     */
    ATTACHMENT_BLEND_MASK = 0xFFFF0000,
    ALL_MASK = 0xFFFFFFFF,
    VIEWPORT_SCISSOR = VIEWPORT | SCISSOR,
    BINDING = ARRAY_BINDING | TEXTURE_BINDING | FRAMEBUFFER_BINDING | VERTEXATTRIB_ENABLED | BUFFER_BINDING | PROGRAM_BINDING,
};

NAMESPACE_AMAZING_ENGINE_END
