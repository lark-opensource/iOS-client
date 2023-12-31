/**
 * @file RendererDevice.h
 * @author lishaoyuan (lishaoyuan@bytedance.com)
 * @brief AGFX RendererDevice
 * GPU rendering api
 * 1. Render program&pipeline create&destroy
 * 2. Render pipeline begin&draw&end
 * 3. Render resources create&update&destroy same as RenderDevice
 * 4. Render state such as viewport&scissor&clear
 * 5. Render texture utils such as blit&read&drawImage
 * @version 1.0
 * @date 2021-09-03
 * @copyright Copyright (c) 2021 Bytedance Inc. All rights reserved.
 */
#ifndef RendererDevice_h
#define RendererDevice_h

#include "Runtime/RenderLib/GPDevice.h"
#include <unordered_set>

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief 渲染设备接口 | Rendering device interface
 * RendererDevice has no virtual exported functions and no members
 * All API with sequence parameter would be a "recording" instead of "executing"
 */
class AMAZING_EXPORT RendererDevice
{
public:
    /**
     * @brief RendererDevice feature switches
     */
    enum Feature : unsigned int
    {
        FlipPatch = 0x1,
        VKUseVulkanCoordinateSystem = 0x2,
        GLES31Android = 0x4,
        ContextSink = 0x8,
        NoGLFence = 0x10,
        SequenceWithoutLock = 0x20,
        BasicDebugLayer = 0x40,
        ResourceDebugLayer = 0x80,
        DebugLayerStrictMode = 0x100,
        GLFlushOptimize = 0x200,
        GLTextureFromNativeBuffer = 0x400,
    };
    /**
     * @brief 渲染设备析构 | Render device destruction
     */
    ~RendererDevice();
    void operator delete(void* ptr);
    void operator delete[](void* ptr);
    /**
     * @brief get source GPDevice
     * @return GPDevice* gpDevice
     */
    GPDevice* getGPDevice();
    /**
     * @brief 获取设备能力表 | Get device capability table
     * Just Like https://www.khronos.org/registry/vulkan/specs/1.2-extensions/man/html/VkPhysicalDeviceFeatures.html
     */
    Caps getCaps();
    /**
     * @brief 获取设备限制表 | Get device restriction table
     * Just Like https://www.khronos.org/registry/vulkan/specs/1.2-extensions/man/html/VkPhysicalDeviceLimits.html
     */
    const Limits& getLimits();
    /**
     * @brief Get device supported macros
     * In OpenGL and Vulkan 
     * Supported macros are "Extension Names"
     * @return std::unordered_set<std::string> 
     */
    std::unordered_set<std::string> getSupportedMacros();
    /**
     * @brief 开始渲染 | Start rendering
     * draw&drawImage and other Render APIs would be called between beginRender and endRender
     * @param fb FrameBuffer Handle
     * @param info Clear Info
     * Clear with begin would get better performance than explict clearFrameBuffer
     * @param seq Sequence
     */
    void beginRender(DeviceFramebuffer fb = 0, const framebuffer_clear_info* info = nullptr, DeviceSequence seq = nullptr);
    /**
     * @brief 结束渲染 | End rendering
     * @param seq Sequence
     */
    void endRender(DeviceSequence seq = nullptr);
    /**
     * @brief 帧开始 | Start of frame
     * @param handle DeviceWindow Handle
     * beginFrame(0) == beginSequence(_default_sequence);
     */
    void beginFrame(DeviceWindow handle = 0);
    void beginFrame(bool needFence, DeviceWindow handle = 0);
    /**
     * @brief 帧结束 | End of frame
     * endFrame() == endSequence() & submit(sequence)
     */
    void endFrame();
    /**
     * @brief 创建framebuffer对象 | Create framebuffer object
     * @param rt framebuffer create struction info
     * @return DeviceFramebuffer framebuffer handle
     */
    DeviceFramebuffer createFramebuffer(const RenderTargetDesc* rt);
    /**
     * @brief 销毁framebuffer对象 | Destroy the framebuffer object
     * @param handle framebuffer handle
     */
    ///
    void destroyFramebuffer(DeviceFramebuffer handle);
    /**
     * @brief [Deprecated] Only use In OpenGL
     * 更新的framebuffer的颜色attachment | The color attachment of the updated framebuffer
     * Update attachment of framebuffer
     * @param handle framebuffer handle
     * @param color color texture
     * @param msaaMode msaa samples
     */
    void attachColor(DeviceFramebuffer handle, DeviceTexture color, const AMGMSAAMode msaaMode = AMGMSAAMode::NONE);
    /**
     * @brief 清除framebuffer | Clear framebuffer
     * 1. Color
     * 2. Depth
     * 3. Stencil
     * All belows clearXXX is only a wrapper for clearFramebuffer
     * @param info clear Info
     * @param seq Sequence
     */
    void clearFramebuffer(const framebuffer_clear_info* info, DeviceSequence seq = nullptr);
    /// 清除颜色attachment | Clear color attachment
    void clearColorAttachment(float r, float g, float b, float a, DeviceSequence seq = nullptr);
    /// 清除深度attachment | Clear depth attachment
    void clearDepthAttachment(float depth, DeviceSequence seq = nullptr);
    /// 清除模版attachment | Clear template attachment
    void clearStencilAttachment(unsigned int stencil, DeviceSequence seq = nullptr);
    /// 清除深度和模版attachment | Clear depth and template attachment
    void clearAttachments(float depth, unsigned int stencil, DeviceSequence seq = nullptr);
    /// 清除颜色和深度attachment | Clear color and depth attachment
    void clearAttachments(float r, float g, float b, float a, float depth, DeviceSequence seq = nullptr);
    /// 清除颜色，深度和模版attachment | Clear color, depth and template attachment
    void clearAttachments(float r, float g, float b, float a, float depth, unsigned int stencil, DeviceSequence seq = nullptr);
    /**
     * @brief 设置视口 | Set viewport
     * Just like vkCmdSetViewport
     * @param x viewport’s upper left corner (x,y).
     * @param y viewport’s upper left corner (x,y).
     * @param width viewport’s width and height
     * @param height viewport’s width and height
     * @param seq Sequence
     */
    void setViewport(float x, float y, float width, float height, DeviceSequence seq = nullptr);
    /**
     * @brief 设置视口 | Set viewport
     * Just like vkCmdSetViewport
     * @param x scissor upper left corner (x,y).
     * @param y scissor upper left corner (x,y).
     * @param width scissor width and height
     * @param height scissor width and height
     * @param seq Sequence
     */
    void setScissor(float x, float y, float width, float height, DeviceSequence seq = nullptr);
    /**
     * @brief 在seq序列中产生绘制指令 | Generate drawing instructions in seq sequence
     * @param handle RenderEntity handle
     * @param seq Sequence
     */
    void draw(RenderEntity handle, DeviceSequence seq = nullptr);
    /**
     * @brief 在seq序列中产生绘制指令 | Generate drawing instructions in seq sequence
     * Draw with extra properties applied
     * @param handle RenderEntity handle
     * @param materialProperties Extra properties
     * @param extraMaterialProperties Extra properties
     * @param seq Sequence
     */
    void draw(RenderEntity handle, const std::unordered_map<int, SharePtr<DeviceProperty>>& materialProperties, const std::unordered_map<int, SharePtr<DeviceProperty>>* extraMaterialProperties = nullptr, DeviceSequence seq = nullptr);
    /**
     * @brief 创建渲染实体 | Create rendering entity
     * RenderEntity is similair with VkRenderPipeline
     * @param geometry Geometry Desc
     * @param pipeline Shader Program
     * @param state Render State
     * @return RenderEntity 渲染实体
     */
    RenderEntity createEntity(const GeometryDesc* geometry, RenderPipeline pipeline, SharePtr<PipelineRenderState> state);
    RenderEntity createEntity(const GeometryDesc* geometry, RenderPipeline pipeline, SharePtr<PipelineRenderState> state, const char* label);
    /**
     * @brief 创建渲染管线对象 | Create a render pipeline object
     * @param shaders render shader including vertex&fragment shaders
     * 1. in GLES it is a text shader(Only support text now)
     * 2. in Vulkan it is a binary shader(Only support SPIRV)
     * 3. in Metal is could be text or binary
     * createPipeline not only compile shader for use but also reflect shader infomations such as inputs, uniforms.
     * @param semantics vertex input attributes mapping
     * @return RenderPipeline 
     */
    RenderPipeline createPipeline(const std::vector<ShaderDesc>& shaders, const VertexAttribMapWrap& semantics);
    RenderPipeline createPipeline(const std::vector<ShaderDesc>& shaders, const VertexAttribMapWrap& semantics, bool flipPatch);
    RenderPipeline createPipelineWithProgramBinarySupport(const std::vector<ShaderDesc>& shaders, const VertexAttribMapWrap& semantics);
    bool getProgramBinary(RenderPipeline pipeline, int32_t* size, void* binary);
    RenderPipeline createPipelineFromProgramBinary(void const* binary, int32_t size, const VertexAttribMapWrap& semantics);
#if AMAZING_PLATFORM == AMAZING_WINDOWS
    RenderPipeline createPipelineWithAngleBinary(const std::vector<ShaderDesc>& shaders, const VertexAttribMapWrap& semantics, const void* binaryProgram, size_t binaryProgramSize);
#endif
    /**
     * @brief draw image, must within beginRender and endRender
     * @param info drawImage Structure Info
     * @param seq Sequence
     * @return bool false with invalid inputs or invalid rendering states
     */
    bool drawImage(const image_draw_info* info, DeviceSequence seq = nullptr);
    bool drawImage(DeviceTexture handle, FlipMode flipMode = FLIP_NONE, RotateMode rotateMode = ROTATE_CW_0, AMGFilterMode filterMode = AMGFilterMode::LINEAR);
    /**
     * @brief read image, must outside beginRender and endRender
     * If srcSize != dstSize there would be a internal blit operation, So the same size would be better
     * @param info readImage Structure Info
     * @return bool false with invalid inputs or invalid rendering states
     */
    ///
    bool readImage(const image_read_info* info);
    bool readImage(DeviceTexture handle, int dstWidth, int dstHeight, void* data, FlipMode flipMode = FLIP_NONE, RotateMode rotateMode = ROTATE_CW_0, AMGFilterMode filterMode = AMGFilterMode::NEAREST, AMGPixelFormat pixelFormat = AMGPixelFormat::RGBA8Unorm);
    bool readImage(DeviceTexture handle, int dstWidth, int dstHeight, void* data, int face, int level, FlipMode flipMode = FLIP_NONE, RotateMode rotateMode = ROTATE_CW_0, AMGFilterMode filterMode = AMGFilterMode::NEAREST, AMGPixelFormat pixelFormat = AMGPixelFormat::RGBA8Unorm);
    /**
     * @brief blit image, must outside beginRender and endRender
     * @param info blitImage Structure Info
     * @return bool 
     */
    bool blitImage(const image_blit_info* info);
    bool blitImage(DeviceTexture src, DeviceTexture dst, FlipMode flipMode = FLIP_NONE, RotateMode rotateMode = ROTATE_CW_0, AMGFilterMode filterMode = AMGFilterMode::LINEAR);
    /**
     * @brief 获得属性块 | Get attribute block
     * @return SharePtr<PropertyBlockKeyInt> Built-In PropertyBlockInt
     */
    SharePtr<PropertyBlockKeyInt> GetPropertyBlockInt();
    /**
     * @brief 获得属性块 | Get attribute block
     * @return SharePtr<PropertyBlockKeyStr> SharePtr<PropertyBlockKeyInt> Built-In PropertyBlockKeyStr
     */
    SharePtr<PropertyBlockKeyStr> GetPropertyBlockStr();
    /**
     * @brief 销毁管线对象 | Destroy the pipeline object
     * @param handle Shader Program
     */
    void destroyPipeline(RenderPipeline handle);
    /**
     * @brief 获得管线的常数表 | Get the constant table of the pipeline
     * @param handle Shader Program
     * @return std::unordered_map<String, SymbolType> Reflected uniforms 
     */
    std::unordered_map<String, SymbolType> getUniformNames(RenderPipeline handle);
    std::unordered_map<String, int> getUniformEnumNames(RenderPipeline handle);
    /**
     * @brief 销毁实体 | Destroy entity
     * @param handle Render Entity
     */
    void destroyEntity(RenderEntity handle);
    /**
     * @brief 更新属性 | Update attributes
     * @param entity Render Entity
     * @param state Render State
     */
    void apply(RenderEntity entity, PipelineRenderState* state);
    /**
     * @brief 更新属性 | Update attributes
     * @param entity Render Entity
     * @param geometry Geometry Desc
     */
    void apply(RenderEntity entity, GeometryDesc* geometry);
    /**
     * @brief 更新属性 | Update attributes
     * Update render pipeline would reset state and geometry
     * @param entity Render Entity
     * @param pipeline Shader Program
     */
    void apply(RenderEntity entity, RenderPipeline pipeline);
    /**
     * @brief 更新属性 | Update attributes
     * All below applys are only a wrapper for this functions
     * @param handle Render Entity
     * @param properties property data
     * @param propertyCount property count
     */
    void apply(RenderEntity handle, const DeviceProperty* properties, int propertyCount);
    void apply(RenderEntity handle, const std::unordered_map<String, SharePtr<DeviceProperty>>& materialProperties);
    void apply(RenderEntity handle, const std::unordered_map<int, SharePtr<DeviceProperty>>& materialProperties);

public:
    /**
     * @brief 释放编译器资源 | Release compiler resources
     * Only supported in GL - glReleaseShaderCompiler
     */
    void flushTextureCaches();
    /**
     * @brief 下发指令并等待指令结束 | Issue the commands and wait for the end of the order
     */
    void finish();
    /// 设置浮点属性 | Set floating point attributes
    void SetFloat(int key, float val);
    /// 设置vec4属性 | Set vec4 attributes
    void SetVector(int key, const Vector4f& vec);
    /// 设置矩阵属性 | Set matrix properties
    void SetMatrix(int key, const Matrix4x4f& mat);
    /// 设置转置矩阵属性 | Set matrix properties
    /// 目前只在windows Angle端有效 | Currently only works on Windows Angle
    void SetTransposeMatrix(int key, const Matrix4x4f& mat);
    /// 设置2D纹理属性 | Set 2D texture properties
    void SetTexture2D(int key, DeviceTexture texId);
    /// 设置cube纹理属性 | Set cube texture attributes
    void SetTextureCube(int key, DeviceTexture texId);
    /// 设置块属性 | Set block properties
    void SetProperty(int key, const float* data, uint8_t rows, uint8_t cols, uint32_t count);
    /// 设置float属性 | Set float attributes
    void SetFloat(String key, float val);
    /// 设置vec4属性 | Set vec4 attributes
    void SetVector(String key, const Vector4f& vec);
    /// 设置矩阵属性 | Set matrix properties
    void SetMatrix(String key, const Matrix4x4f& mat);
    /// 设置转置矩阵属性 | Set matrix properties
    /// 目前只在windows Angle端有效 | Currently only works on Windows Angle
    void SetTransposeMatrix(String key, const Matrix4x4f& mat);
    /// 设置2D纹理属性 | Set 2D texture properties
    void SetTexture2D(String key, DeviceTexture texId);
    /// 设置cube纹理属性 | Set cube texture attributes
    void SetTextureCube(String key, DeviceTexture texId);
    /// 设置块属性 | Set block properties
    void SetProperty(String key, const float* data, uint8_t rows, uint8_t cols, uint32_t count);
    /**
     * @brief set uniforms name to integer mapping
     * @param enumNameList The Kth string in enumNameList set uniform to enumKey K
     */
    void setEnumNameList(const std::vector<String>& enumNameList);

    // texture
    /// 从外部纹理创建纹理对象 | Create texture objects from external textures
    /// For OpenGL texID is a interger
    /// For Other Backends texID is a native handle
    /// 1. Metal MTLTexture
    /// 2. Vulkan VkImage
    /// 3. DX D3D11Resource
    DeviceTexture createTextureFromExternalTexture(unsigned* texId, ImageType type, AMGPixelFormat format, int width, int height, bool textureYFlip = false, bool rtYFlip = false);
    DeviceTexture createTextureFromExternalTexture(unsigned* texId, ImageType type, AMGPixelFormat format, int width, int height, bool textureYFlip, bool rtYFlip, const char* label);
    DeviceTexture createTextureFromExternalTexture(unsigned* texId, NativeBuffer nativeBuffer, ImageType type, AMGPixelFormat format, int width, int height, bool textureYFlip, bool rtYFlip, const char* label);
    /**
     * @brief 从系统原生缓存创建纹理对象 | Create texture objects from the system's native cache
     * 1. IOS&MacOS is CVPixelBuffer
     * 2. Android is AHardwareBuffer
     * 3. Windows is ?
     */
#if AMAZING_PLATFORM == AMAZING_IOS || AMAZING_PLATFORM == AMAZING_MACOS || AMAZING_PLATFORM == AMAZING_WINDOWS
    DeviceTexture createTextureFromNativeBuffer(NativeBuffer nativeBuffer, bool textureYFlip = false, bool rtYFlip = false, bool rbFlip = false);
    DeviceTexture createTextureFromNativeBuffer(NativeBuffer nativeBuffer, bool textureYFlip, bool rtYFlip, bool rbFlip, const char* label);
    DeviceTexture createTextureFromNativeBuffer(const texture_from_nativeBuffer_create_info* info);
    /**
     * @brief [Deprecated] update texture(created by createTextureFromNativeBuffer)
     * @param texture texture handle
     * @param nativeBuffer system native buffer
     * @param rbFlip whether flip red-greee
     * @return bool 
     */
    bool updateTextureWithNativeBuffer(DeviceTexture texture, NativeBuffer nativeBuffer, bool rbFlip = false);
#endif
#if AMAZING_PLATFORM == AMAZING_IOS || AMAZING_PLATFORM == AMAZING_MACOS
    DeviceTexture createTextureFromPlane(NativeBuffer buffer, size_t plane, AMGPixelFormat pixelFormat);
    DeviceTexture createTextureFromPlane(texture_from_nativeBuffer_create_info* info, AMGPixelFormat pixelFormat);
    bool updateTextureWithPlane(DeviceTexture texture, NativeBuffer buffer, size_t plane, AMGPixelFormat pixelFormat);
#endif
    /**
     * @brief [Deprecated] 从裸数据创建纹理对象 | Create texture objects from raw data
     * It would be moved to Utils module
     */
    ///
    DeviceTexture createTextureFromRawData(const texture_convert_info* info);
    /**
     * @brief [Deprecated] 从NV21数据创建纹理对象 | Create texture objects from NV21 data
     * It would be moved to Utils module
     */
    DeviceTexture createTextureFromNv21Data(int width, int height, const void* data, FlipMode flipMode = FlipMode::FLIP_NONE, RotateMode rotateMode = RotateMode::ROTATE_CW_0, AMGPixelFormat format = AMGPixelFormat::RGBA8Unorm, const char* label = "agfx: texture(nv21data)");

    /**
     * @brief 创建序列 | Create a sequence
     * If this is a GPDevice this sequence would also record render commands
     * @return DeviceSequence sequence recording commands
     */
    DeviceSequence createSequence();
    /**
     * @brief 销毁序列 | Destroy the sequence
     * @param handle sequence recording commands
     */
    void destroySequence(DeviceSequence handle);
    /**
     * @brief 开始序列 | Start sequence
     * Start sequence for recording commmands
     * beginSequence should be called before all apis with sequence parameters
     * beginSequence would clear all recorded commands in sequence and restart recording
     * @param handle sequence recording commands
     */
    void beginSequence(DeviceSequence handle);
    /**
     * @brief 开始序列 | Start sequence
     * @param handle sequence recording commands
     * @param needFence True: need fence object which returned by submit False: submiting sequence return NULL and better performance
     * Warning: in Android8.1&ArmGPU waitFence would cause crashes with a low probability so this ability is risk.
     */
    void beginSequence(DeviceSequence handle, bool needFence);
    /**
     * @brief 结束序列 | End sequence
     * endSequence should be called after all apis with sequence parameters
     * endSequence only end sequence's record but not submit/excute sequence's commands
     * 
     * @param handle sequence recording commands
     */
    void endSequence(DeviceSequence handle = nullptr);
    /**
     * @brief 提交队列 | Submit sequence
     * A sequence needed execution muse be submitted and executed after submit.
     * It is nowly not promised ”sequential execution“ except for OpenGL Single-Thread
     * Which means that the sequence submitted later may be executed earlier than the sequence submitted earlier
     * @param handle sequence recording commands
     * @param unNeedSchedule bool 
     * @return DeviceFence fence for cpu-waiting
     */
    DeviceFence submit(DeviceSequence handle, bool unNeedSchedule = false);
    /**
     * @brief CPU-wait fence until completed 
     * @param handle fence handle
     */
    void wait(DeviceFence handle);
    /**
     * @brief GPU-wait fence until reached
     * Prevents sequence gpu commands from being recorded by the sequence until the given fence is reached.
     * @param handle fence handle
     */
    void waitForSequence(DeviceFence handle, DeviceSequence sequence = nullptr);
    /**
     * @brief create Window handle for presenting
     * @param win native window handle
     * 1. IOS is a UIView
     * 2. Android is a EGLNativeWindowType
     * 3. MacOS is NSView
     * 4. Windows is HWND
     * @return DeviceWindow cross-platform window handle
     */
    DeviceWindow createWindow(NativeWindow win);
    DeviceWindow createWindowFromSurface(NativeSurface surface);
    /**
     * @brief destroy window handle
     * @param handle cross-platform window handle
     */
    void destroyWindow(DeviceWindow handle);

    DeviceBuffer createBuffer(BufferType type, BufferUsage usage, int size, const void* data);
    /**
     * @brief create buffer object
     * DeviceBuffer could be used as 
     * 1. Vertex&Index Buffer
     * 2. Uniform&Storage Buffer
     * 3. TransformFeedback Buffer
     * 4. Indirect Draw Buffer
     * 5. ......
     * @param type buffer Type
     * @param usage buffer Usage(Update Frequency)
     * @param size buffer size(bytes)
     * @param data buffer initial data which could be NULL
     * @param label buffer label for debugging
     * @return DeviceBuffer buffer handle
     */
    DeviceBuffer createBuffer(BufferType type, BufferUsage usage, int size, const void* data, const char* label);
    /**
     * @brief destroy buffer object
     * @param handle buffer handle
     */
    void destroyBuffer(DeviceBuffer handle);
    /**
     * @brief [DEPRECATED] renew a buffer object 
     * recreate a buffer object with parameters same as before except for size&data
     * @param handle buffer handle
     * @param size buffer new size(bytes)
     * @param data buffer initial data which could be NULL
     */
    void renewBuffer(DeviceBuffer handle, int size, const void* data);
    /**
     * @brief update buffer's data
     * @param handle buffer handle
     * @param offset update offset
     * @param size update size(bytes)
     * @param data update data pointer
     */
    void updateBuffer(DeviceBuffer handle, int offset, int size, const void* data);
    /**
     * @brief map all of a buffer object's data store into the client's address space
     * @param handle buffer handle
     * @return void* CPU address
     */
    void* mapBuffer(DeviceBuffer handle);
    /**
     * @brief release the mapping of a buffer object's data store into the client's address space
     * @param handle buffer handle
     */
    void unmapBuffer(DeviceBuffer handle);
    /**
     * @brief [DEPRECATED] create texture
     * @param info [DEPRECATED] texture_create_info
     * @return DeviceTexture texture handle
     */

    /**
     * @brief [DEPRECATED] create texture
     * @param info [DEPRECATED] texture_create_info
     * @return DeviceTexture texture handle
     */
    DeviceTexture createTexture(const texture_create_info* info);
    /**
     * @brief 创建纹理对象 | Create texture objects
     * create texture with tex_create_info which including
     * 1. texture image properties
     * 2. texture initial data
     * 3. texture sampler properties
     * 4. texture other infomations
     * @param info tex_create_info structure specifying the parameters of a newly created image object
     * @return DeviceTexture texture handle
     */
    DeviceTexture createTexture(const tex_create_info* info);
    /**
     * @brief 销毁纹理对象 | Destroy the texture object
     * @param handle texture handle
     */
    void destroyTexture(DeviceTexture handle);
    /**
     * @brief 更新纹理对象 | Update texture object
     * update texture with texture_update_info which including
     * 1. update position&size(bytes)
     * 2. update data
     * 3. genLevels decide whether generate MipMap
     * @param handle texture handle
     * @param info updateTexture structure specifying the parameters of updating image object
     */
    void updateTexture(DeviceTexture handle, const texture_update_info* info);
    /**
     * @brief retire texture created by Android-External-Image
     * Only suppported in Android-GL
     * @param handle external texture handle
     * @return void* external image
     */
    void* retireTexture(DeviceTexture handle);
    /**
     * @brief 设置纹理对象的坐标寻址模式 | Set the coordinate addressing mode of the texture object
     * REPEAT: The integer part of the coordinate will be ignored and a repeating pattern is formed.
     * MIRRORED: The texture will also be repeated, but it will be mirrored when the integer part of the coordinate is odd.
     * CLAMP: The coordinate will simply be clamped between 0 and 1.
     * BORDER: The coordinates that fall outside the range will be given a specified border color.
     * @param handle texture handle
     * @param info texture_create_info only use wrapMode
     */
    void setTextureWrapMode(DeviceTexture handle, const texture_create_info* info);
    /**
     * @brief 设置纹理对象的坐标寻址模式 | Set the coordinate addressing mode of the texture object
     * @param handle texture handle
     * @param u wrapMode U
     * @param v wrapMode V
     * @param w wrapMode W
     */
    void setTextureWrapMode(DeviceTexture handle, AMGWrapMode u, AMGWrapMode v, AMGWrapMode w = AMGWrapMode::CLAMP);
    /**
     * @brief 设置纹理对象的过滤模式 | Set the filter mode of the texture object
     * NEAREST Returns the value of the texture element that is nearest (in Manhattan distance) to the specified texture coordinates.
     * LINEAR Returns the weighted average of the four texture elements that are closest to the specified texture coordinates.
     * @param handle texture handle
     * @param info texture_create_info only use filterMode
     */
    void setTextureFilterMode(DeviceTexture handle, const texture_create_info* info);
    /**
     * @brief 设置纹理对象的过滤模式 | Set the filter mode of the texture object
     * @param handle texture handle
     * @param mag filterMode mag
     * @param min filterMode min
     * @param mip filterMode mipmap
     */
    void setTextureFilterMode(DeviceTexture handle, AMGFilterMode mag, AMGFilterMode min, AMGFilterMipmapMode mip = AMGFilterMipmapMode::NONE);
    /**
     * @brief 设置纹理对象的各向异性采样 | Set the maxAnisotropy of the texture object
     * @param handle texture handle
     * @param maxAnisotropy anisotropy with default : 1.0
     */
    void setTextureMaxAnisotropy(DeviceTexture handle, int maxAnisotropy);
    /**
     * @brief 设置纹理对象的各向异性采样 | Set the maxAnisotropy of the texture object
     * @param handle texture handle
     * @param info tex_create_info only use filterMode
     */
    void setTextureMaxAnisotropy(DeviceTexture handle, const tex_create_info* info);
    /**
     * @brief 释放所有资源 | Release all resources
     * 1. Buffers
     * 2. Textures
     * 3. FrameBuffers
     * 4. Entity&Pipeline
     * 5. Cache Resources
     * @param releaseCacheOnly whether only release cache resources
     */
    // release all resource
    ///
    void releaseResources(bool releaseCacheOnly);

    /**
     * @brief update texture 
     * only with addr
     * update size is all texture's size without offset
     * @param handle texture handle
     * @param addr texture update Data
     */
    void updateTexture(DeviceTexture handle, const void* addr);
    /**
     * @brief 纹理对象生成Mipmap | Update texture object
     * @param handle texture handle
     * @param seq Sequence
     */
    void genTextureMipmap(DeviceTexture handle, DeviceSequence seq = nullptr);
    /**
     * @brief /// 创建2D纹理对象 | Create 2D texture objects
     * createTexture2D is same as createTexture. their difference is only parameter passing form
     * @param width texture width
     * @param height texture height
     * @param addrs texture data
     * @param pixelFormat texture format
     * @param mag texture mag filter
     * @param min texture min filter
     * @param u texture u wrap
     * @param v texture v wrap
     * @param sizes texture size(bytes)
     * Only one layer so sizes is only one size
     * @param label texture label for debugging
     * @param textureYFlip 
     * Only used in OpenGL FlipPatch Mode
     * @param rtYFlip 
     * Only used in OpenGL FlipPatch Mode
     * @return DeviceTexture texture handle
     */
    DeviceTexture createTexture2D(int width,
                                  int height,
                                  const void* const* addrs = nullptr,
                                  AMGPixelFormat pixelFormat = AMGPixelFormat::RGBA8Unorm,
                                  AMGFilterMode mag = AMGFilterMode::LINEAR,
                                  AMGFilterMode min = AMGFilterMode::LINEAR,
                                  AMGWrapMode u = AMGWrapMode::CLAMP,
                                  AMGWrapMode v = AMGWrapMode::CLAMP,
                                  int* sizes = nullptr,
                                  const char* label = "agfx: texture",
                                  bool textureYFlip = false,
                                  bool rtYFlip = false);

    ///create 3D Texture
    DeviceTexture createTexture3D(int width,
                                  int height,
                                  int depth,
                                  const void* const* addrs = nullptr,
                                  AMGPixelFormat pixelFormat = AMGPixelFormat::RGBA8Unorm,
                                  AMGFilterMode mag = AMGFilterMode::LINEAR,
                                  AMGFilterMode min = AMGFilterMode::LINEAR,
                                  AMGWrapMode u = AMGWrapMode::CLAMP,
                                  AMGWrapMode v = AMGWrapMode::CLAMP,
                                  int* sizes = nullptr,
                                  const char* label = "agfx: texture",
                                  bool textureYFlip = false,
                                  bool rtYFlip = false);

    /**
     * @brief /// 创建2D纹理对象 | Create 2D texture objects
     * @param width texture width
     * @param height texture height
     * @param mipmap texture mipmapMode
     * @param addrs texture data
     * @param pixelFormat texture format
     * @param mag texture mag filter
     * @param min texture min filter
     * @param u texture u wrap
     * @param v texture v wrap
     * @param sizes texture size(bytes)
     * Only one layer so sizes is only one size
     * @param label texture label for debugging
     * @param textureYFlip 
     * Only used in OpenGL FlipPatch Mode
     * @param rtYFlip 
     * Only used in OpenGL FlipPatch Mode
     * @return DeviceTexture texture handle
     */
    DeviceTexture createTexture2D(int width,
                                  int height,
                                  AMGFilterMipmapMode mipmap,
                                  const void* const* addrs = nullptr,
                                  AMGPixelFormat pixelFormat = AMGPixelFormat::RGBA8Unorm,
                                  AMGFilterMode mag = AMGFilterMode::LINEAR,
                                  AMGFilterMode min = AMGFilterMode::LINEAR,
                                  AMGWrapMode u = AMGWrapMode::CLAMP,
                                  AMGWrapMode v = AMGWrapMode::CLAMP,
                                  int* sizes = nullptr,
                                  const char* label = "agfx: texture",
                                  bool textureYFlip = false,
                                  bool rtYFlip = false);
    /**
     * @brief /// 创建2D纹理对象 | Create 2D texture objects
     * @param width texture width
     * @param height texture height
     * @param mipmap texture mipmapMode
     * @param mipmapLevelCount texture mipmap level count
     * @param addrs texture data
     * addrs length == mipmapLevelCount
     * @param pixelFormat texture format
     * @param mag texture mag filter
     * @param min texture min filter
     * @param u texture u wrap
     * @param v texture v wrap
     * @param sizes texture size(bytes)
     * sizes length == mipmapLevelCount
     * @param label texture label for debugging
     * @param textureYFlip 
     * Only used in OpenGL FlipPatch Mode
     * @param rtYFlip 
     * Only used in OpenGL FlipPatch Mode
     * @return DeviceTexture texture handle
     */
    DeviceTexture createTexture2D(int width,
                                  int height,
                                  AMGFilterMipmapMode mipmap,
                                  int mipmapLevelCount,
                                  const void* const* addrs = nullptr,
                                  AMGPixelFormat pixelFormat = AMGPixelFormat::RGBA8Unorm,
                                  AMGFilterMode mag = AMGFilterMode::LINEAR,
                                  AMGFilterMode min = AMGFilterMode::LINEAR,
                                  AMGWrapMode u = AMGWrapMode::CLAMP,
                                  AMGWrapMode v = AMGWrapMode::CLAMP,
                                  int* sizes = nullptr,
                                  const char* label = "agfx: texture",
                                  bool textureYFlip = false,
                                  bool rtYFlip = false);

    /**
     * @brief 获取渲染设备类型 | Get the type of rendering device
     * @return RendererType 
     */
    RendererType getRendererType() const;
    /**
     * @brief [DEPRECATED] get ComputerDevice pointer
     * @return ComputerDevice* ComputerDevice pointer
     */
    ComputerDevice* getComputerDevice();
    /**
     * @brief [DEPRECATED] get RendererDevice pointer
     * @return RendererDevice* RendererDevice pointer
     */
    RendererDevice* getRendererDevice();
    /**
     * @brief bindMainContext
     * Only valid in setContextSink(true)
     * Bind accuracy context
     */
    static void bindMainContext();
    static void bindMainContext(ContextBindType contextIndex);
    /**
     * @brief unbindMainContext
     * Only valid in setContextSink(true)
     * Unbind internal main context for GL external calls
     */
    static void unbindMainContext();
    /**
     * @brief reset main context GL-State
     * Only valid in setContextSink(true)
     * Reset state for GL external calls
     * @param mask 
     */
    static void resetMainContextState(uint64_t mask);
    // lifecycle control
    /**
     * @brief 初始化 | initialization
     * 1. init gpu environment
     * 2. init featureMode & AB Config
     * 3. init internal resource such as default sequence
     */
    void init();
    /**
     * @brief 退出 | drop out
     * 1. release gpu environment
     * 2. release all gpu resource created by AGFX
     * 3. release internal resources 
     */
    ///
    void deinit();
    /**
     * @brief 切入 | Cut in
     * called before all agfx api calls
     * @param flag binding flag
     * true/false special for OpenGL
     * bind(true) is same as bindMainContext
     * bind(flag) would increase ref count For example:
     * ...
     * bind
     * bind
     * unbind
     * bind
     * unbind
     * unbind
     * Only last unbind would execute really unbind operation
     */
    void bind(bool flag = false);
    /**
     * @brief 切出 | Cut out
     * called after all agfx api calls
     * @param forceUnbind unbinding flag
     * true: binding with ignoring ref count 
     * false: binding with ref count
     */
    void unbind(bool forceUnbind = false);
    /**
     * @brief [NOT IMPLEMENTED] 暂停 | time out
     */
    void pause();
    /**
     * @brief [NOT IMPLEMENTED] 恢复 | restore
     */
    void resume();
    /**
     * @brief [NOT IMPLEMENTED] 下一帧 | newFrame
     * AGFX nowly does not control frame 
     */
    void newFrame();
    /**
     * @brief 同步设备状态 | Sync device status
     * API For OpenGL ES Usage
     * Sync external OpenGL ES State
     * Because internal GL calls would check dirty
     * For Example:
     * RendererGLES would finally call glBindBuffer
     * Before call glBindBuffer
     * RendererGLES would check whether is equal between setting and store state
     * int ti = BufferTargetTypeMap(target); 
     * if (state.bindings.bufferTargets[ti] == buffer)
     *     returnl
     * state.bindings.bufferTargets[ti] = buffer;
     * GL_CHECK(glBindBuffer(target, buffer));
     */
    void syncState();
    /**
     * @brief 同步设备状态 | Sync device status
     * @param mask StateBit mask bits
     */
    void syncState(uint64_t mask);
    /**
     * @brief 设备状态压栈 | Device status push
     * push synced gl state to stack
     * when pop all gl state would be set to gl context
     */
    void pushState();
    /**
     * @brief 设备状态压栈 | Device status push
     * @param mask StateBit mask bits
     */
    void pushState(uint64_t mask);
    /**
     * @brief 设备状态出栈 | Device status pop
     * restore all gl state by stack
     */
    void popState();
    /**
     * @brief 设备状态重置 | Device status reset
     * reset all gl state and binding gl state to zero
     * @param mask StateBit mask bits
     */
    ///
    void resetState(uint64_t mask);
    /**
     * @brief 获得当前已经使用的显存 | Get the currently used video memory
     * @return int64_t allocated memory size(bytes)
     */
    int64_t getAllocatedGPUMemory();
    /**
     * @brief ContextSink Switch
     * ContextSink means that AGFX controls GL-Context usages
     * If it is enabled
     * 0. init first agfx device would create a main GL-Context and 4 shared GL-Context
     * 1. bind() would bind a Shared GL-Context
     * 2. bind(true) would bind a Main GL-Context
     * @param enableContextSink switch 
     */
    static void setContextSink(bool enableContextSink = false);
    /**
     * @brief ContextSinkV2 Switch
     * If ContextSinkV2 is enabled
     * 0. Init AGFX Device with a External Context would create a device-local context group (1 main context + 1 shared context)
     * 1. Other Cases: just like ContextSink
     * @param enableContextSink2 switch
     */
    static void setContextSink2(bool enableContextSink2 = false);
    /**
     * @brief [TEMP] Metal Refactor AB
     * @param enable use new metal implementation
     */
    static void setMetalRefactorEnable(bool enable);
    static bool getMetalRefactorEnable();
};

NAMESPACE_AMAZING_ENGINE_END

#endif // RENDERER_DEVIDE_H
