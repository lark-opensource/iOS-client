/**
 * @file ComputerDevice.h
 * @author fanwenjie.tiktok (fanwenjie.tiktok.com)
 * @brief AGFX ComputerDevice
 * 
 * GPU compute api
 * 1. Compute program&pipeline create&destroy
 * 2. Compute pipeline begin&dispatch&end
 * 3. Compute resources create&update&destroy same as RenderDevice
 * @version 1.0
 * @date 2021-08-31
 * @copyright Copyright (c) 2021 Bytedance Inc. All rights reserved.
 */
#ifndef ComputerDevice_h
#define ComputerDevice_h

#include "Runtime/RenderLib/GPDevice.h"

NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief ComputerDevice Export APIs
 * ComputerDevice has no virtual exported functions and no members
 */

class AMAZING_EXPORT ComputerDevice
{
public:
    /**
     * @brief destructor function
     */
    ~ComputerDevice();
    /**
     * @brief destructor operator
     * @param ptr ComputerDevice pointer
     */
    void operator delete(void* ptr);
    /**
     * @brief destructor operator
     * @param ptr ComputerDevice pointer array
     */
    void operator delete[](void* ptr);
    /**
     * @brief Get GPDevice pointer if this is a valid GPDevice
     * It is not safe conversion. a getGPDevice call by wrong pointer could cause crash!
     * @return GPDevice* GPDevice pointer
     */
    GPDevice* getGPDevice();
    /**
     * @brief 开始计算 | start calculating
     * beginCompute should be called before any dispatch call which change current sequence to compute state.
     * @param seq recording sequence 
     */
    void beginCompute(DeviceSequence seq = nullptr);
    /**
     * @brief 结束计算 | End calculation
     * endCompute should be called after any dispatch call when need end compute pipeline.
     * @param seq recording sequence 
     */
    void endCompute(DeviceSequence seq = nullptr);
    /**
     * @brief 创建计算实体 | Create calculated entity
     * @param pipeline a ComputePipeline handle
     * @return ComputeEntity compute entity which could be dispatched
     */
    ComputeEntity createEntity(ComputePipeline pipeline);
    /**
     * @brief 创建计算管线对象 | Create a compute pipeline object
     * @param shader compute shader resource
     * 1. in GLES it is a text shader(Only support text now)
     * 2. in Vulkan it is a binary shader(Only support SPIRV)
     * 3. in Metal is could be text or binary
     * createPipeline not only compile shader for use but also reflect shader infomations such as inputs, uniforms.
     * @return ComputePipeline 
     */
    ComputePipeline createPipeline(const ShaderDesc& shader);
#if AMAZING_PLATFORM == AMAZING_WINDOWS
    ComputePipeline createPipelineWithAngleBinary(const ShaderDesc& shader, const void* binaryProgram, size_t binaryProgramSize);
#endif
    /**
     * @brief 销毁管线对象 | Destroy the pipeline object
     * It not is safe conversion.
     * If handle is NULL or Wild Pointer, the destroyPipeline would be failed and print error logs which cause crashes.
     * @param handle compute pipeline handle
     */
    void destroyPipeline(ComputePipeline handle);
    /**
     * @brief 销毁实体 | Destroy entity
     * It not is safe conversion.
     * If handle is NULL or Wild Pointer, the destroyPipeline would be failed and print error logs which cause crashes.
     * @param handle compute entity which could be dispatched
     */
    void destroyEntity(ComputeEntity handle);
    /**
     * @brief apply数据 | apply data
     * update uniforms to handle which is effective immediately. For example:
     * ......
     * beginCompute
     * apply
     * dispatch
     * apply 
     * dispatch
     * endCompute
     * ......
     * The second dispatch is different with first dispatch which all be recorded in sequence.
     * However, If apply a uniform buffer to entity and change buffer before submit sequence, 
     * the final data would be the final buffer data and the halfway data is not recorded in sequence.
     * the sequence only record pure textures, uniforms and uniform buffer ids which not include uniform buffer data.
     * @param handle compute entity which could be dispatched and applied
     * @param properties property including textures, images, uniforms, uniform buffers, storage buffers 
     * @param propertyCount property count
     */
    void apply(ComputeEntity handle, const DeviceProperty* properties, int propertyCount);
    /**
     * @brief 命令队列中生成计算指令 | Generate calculation instructions in the seq sequence
     * @param handle ComputeEntity
     * @param x The number of work groups to be launched in the X dimension.
     * @param y The number of work groups to be launched in the Y dimension.
     * @param z The number of work groups to be launched in the Z dimension.
     * @param seq recording sequence 
     */
    void dispatch(ComputeEntity handle, unsigned x, unsigned y, unsigned z, DeviceSequence seq = nullptr);
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
     * @brief CPU-wait fence until reached
     * Wait sequence gpu commands for finish
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
    /**
     * @brief destroy window handle
     * @param handle cross-platform window handle
     */
    void destroyWindow(DeviceWindow handle);
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
     * @param size buffer Size
     * @param data buffer initial data which could be NULL
     * @param label buffer label for debugging
     * @return DeviceBuffer buffer handle
     */
    DeviceBuffer createBuffer(BufferType type, BufferUsage usage, int size, const void* data, const char* label = "agfx: buffer");
    /**
     * @brief destroy buffer object
     * @param handle buffer handle
     */
    void destroyBuffer(DeviceBuffer handle);
    /**
     * @brief [DEPRECATED] renew a buffer object 
     * recreate a buffer object with parameters same as before except for size&data
     * @param handle buffer handle
     * @param size buffer new size
     * @param data buffer initial data which could be NULL
     */
    void renewBuffer(DeviceBuffer handle, int size, const void* data);
    /**
     * @brief update buffer's data
     * @param handle buffer handle
     * @param offset update offset
     * @param size update size
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
     * 1. update position&size
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
     * @param sizes texture sizes
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
     * @param sizes texture sizes
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
     * @param sizes texture sizes
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
     * @return int64_t allocated memory size
     */
    int64_t getAllocatedGPUMemory();

#if AGFX_RAY_TRACING
    Intersector createIntersector(unsigned rayStride);
    AccelerationStructure createAccelerationStructure(DeviceBuffer vertexPosBuf, DeviceBuffer triangleMaskBuf, unsigned triangleCount);
    void intersect(intersect_info const* info, DeviceSequence seq = nullptr);
#endif
};

NAMESPACE_AMAZING_ENGINE_END

#endif /* ComputerDevice_h */
