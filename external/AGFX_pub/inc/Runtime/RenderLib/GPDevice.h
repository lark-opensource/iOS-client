/**
 * @file GPDevice.h
 * @author lishaoyuan (lishaoyuan@bytedance.com)
 * @brief General Process Device
 * create device and get specific(Render&Compute) ability
 * @version 1.0
 * @date 2021-09-01
 * @copyright Copyright (c) 2021 Bytedance Inc. All rights reserved.
 */
#ifndef GPDevice_h
#define GPDevice_h

#include "Runtime/RenderLib/GPDeviceType.h"

NAMESPACE_AMAZING_ENGINE_BEGIN
class ComputerDevice;
class RendererDevice;

/**
 * @brief General Process Device
 * Including 
 * 1. create specific device 
 * 2. create GLES device with higher version
 * 3. get RendererDevice&ComputerDevice for GPU usages
 */
class AMAZING_EXPORT GPDevice
{
public:
    /**
     * @brief 根据参数创建渲染设备 | Create a rendering device based on parameters
     * @param type device type
     * @param features device features 
     * FlipPatch: auto-flip with texture (only support in GL)
     * PropertyDirty: [DEPRECATED]
     * GLES31Android: createGLESX with versions Up to ES3.1
     * ContextSink: device with internal managed gl contexts
     * NoGLFence: deivce with no internal fence object
     * SequenceWithoutLock: device with no sequence mutex lock
     * @return GPDevice* General Process Device
     */
    static GPDevice* createDevice(RendererType type, unsigned features = 0u);
    /**
     * @brief 根据当前GLES context创建渲染设备 | Create a rendering device based on the current GLES context
     * Invalid Usage:
     * No curent GL Context and No ContextSink Feature
     * Valid Usage:
     * 1. No ContextSink Feature but current context is valid (Use Current Context version)
     * 2. Enable ContextSink and setContextSink(true) (Use Sink Context version)
     * 3. No ContextSink and setContextSink(true) and current context is NULL (Use Sink Context version)
     * @param features device features 
     * @return GPDevice* General Process Device(GLES)
     */
    ///
    static GPDevice* createGLESX(unsigned features = 0u);
    /**
     * @brief 根据参数创建渲染设备，创建的设备和传入设备可以共享资源 | Create a rendering device based on parameters
     * Wwo device would share resources(textures)
     * Curently support in GL&Metal
     * @param type device type
     * @param device shared device
     * @param features device features 
     * @return GPDevice* General Process Device(GLES or Metal)
     */
    static GPDevice* createDevice(RendererType type, GPDevice* device, unsigned features = 0u);
    /**
     * @brief 根据当前的GLES context创建渲染设备，创建的设备和传入设备可以共享资源 | Create a rendering device based on the current GLES context
     * @param device shared device
     * @param features device features 
     * @return GPDevice* eneral Process Device(GLES or Metal)
     */
    static GPDevice* createGLESX(GPDevice* device, unsigned features = 0u);
    /**
     * @brief 根据参数创建渲染设备 | Create a rendering device based on parameters
     * @param type device type
     * @param name device name Debug Layer
     * @param features device features
     * FlipPatch: auto-flip with texture (only support in GL)
     * PropertyDirty: [DEPRECATED]
     * GLES31Android: createGLESX with versions Up to ES3.1
     * ContextSink: device with internal managed gl contexts
     * NoGLFence: deivce with no internal fence object
     * SequenceWithoutLock: device with no sequence mutex lock
     * @return GPDevice* General Process Device
     */
    static GPDevice* createDevice(RendererType type, char const* name, unsigned features = 0u);
    /**
     * @brief 根据当前GLES context创建渲染设备 | Create a rendering device based on the current GLES context
     * Invalid Usage:
     * No curent GL Context and No ContextSink Feature
     * Valid Usage:
     * 1. No ContextSink Feature but current context is valid (Use Current Context version)
     * 2. Enable ContextSink and setContextSink(true) (Use Sink Context version)
     * 3. No ContextSink and setContextSink(true) and current context is NULL (Use Sink Context version)
     * @param name device name Debug Layer
     * @param features device features
     * @return GPDevice* General Process Device(GLES)
     */
    ///
    static GPDevice* createGLESX(char const* name, unsigned features = 0u);
    /**
     * @brief 根据参数创建渲染设备，创建的设备和传入设备可以共享资源 | Create a rendering device based on parameters
     * Wwo device would share resources(textures)
     * Curently support in GL&Metal
     * @param type device type
     * @param device shared device
     * @param name device name Debug Layer
     * @param features device features
     * @return GPDevice* General Process Device(GLES or Metal)
     */
    static GPDevice* createDevice(RendererType type, GPDevice* device, char const* name, unsigned features = 0u);
    /**
     * @brief 根据当前的GLES context创建渲染设备，创建的设备和传入设备可以共享资源 | Create a rendering device based on the current GLES context
     * @param device shared device
     * @param name device name Debug Layer
     * @param features device features
     * @return GPDevice* eneral Process Device(GLES or Metal)
     */
    static GPDevice* createGLESX(GPDevice* device, char const* name, unsigned features = 0u);
    GPDevice* getGPDevice();
    /**
     * @brief 设备析构 | Device destruction
     */
    ~GPDevice();
    /**
     * @brief destructor operator
     * @param ptr GPDevice pointer
     */
    void operator delete(void* ptr);
    /**
     * @brief destructor operator
     * @param ptr GPDevice pointer array
     */
    void operator delete[](void* ptr);
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
    void resetState(uint64_t mask);
    /**
     * @brief 获得当前已经使用的显存 | Get the currently used video memory
     * @return int64_t allocated memory size
     */
    int64_t getAllocatedGPUMemory();
    /**
     * @brief Only with Dynamic-Angle
     * If use dynamic-angle AGFX need a angle dynamic library for load GL&EGL functions
     * @param filename angle dynamic library path
     * @param type angle SearchType
     */
    static void initEGLLibraryWithPath(const char* filename, int type);
    static void initGLESv2LibraryWithPath(const char* filename, int type);
    static void initEGLLibraryWithFunc(void* getEGLProcAddress);
    static void initGLESv2LibraryWithFunc(void* getGLESProcAddress);

    static void setDebugLayerEnable(bool enable);
    static void setDebugLayerStrictModeEnable(bool enable);
    static void setAmazingDebugLayerLogLevel(int logLevel);

    static void setLogFileFuncCaller(int (*pfunc)(int, const char*));
};

NAMESPACE_AMAZING_ENGINE_END

#endif /* GPDevice_h */
