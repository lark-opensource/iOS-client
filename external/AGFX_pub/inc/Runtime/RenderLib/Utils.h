//
//  Utils.h
//  effect_sdk
//
//  Created by fanwenjie.tiktok on 2020/4/28.
//

#ifndef Utils_h
#define Utils_h

#include "Runtime/RenderLib/RendererDeviceTypes.h"
#include "Runtime/RenderLib/RendererDevice.h"
#include "Runtime/RenderLib/ComputerDevice.h"

#define AGFX_AUTO_BIND(device) Utils::RendererDeviceBindWarpper auto_bind(device);
#define AGFX_AUTO_SYNC_STATE(device) Utils::RendererDeviceStateWarpper auto_bind(device);

NAMESPACE_AMAZING_ENGINE_BEGIN

class GPDevice;
class RendererDevice;
class ComputerDevice;
namespace Utils
{
// clang-format off
static const float defaultTransform[4][4] =
{
    {+1.0000f, +1.0000f, +1.0000f, +0.0000f},
    {+0.0000f, -0.3441f, +1.7720f, +0.0000f},
    {+1.4020f, -0.7141f, +0.0000f, +0.0000f},
    {-0.7010f, +0.5291f, -0.8860f, +1.0000f},
};
// clang-format on
void AMAZING_EXPORT bitonicSortU32(GPDevice* device, DeviceBuffer srcBuf, uint32_t count, DeviceBuffer dstBuf, DeviceBuffer idxBuf, bool descend = false, DeviceSequence sequence = nullptr);
void AMAZING_EXPORT bitonicSortF32(GPDevice* device, DeviceBuffer srcBuf, uint32_t count, DeviceBuffer dstBuf, DeviceBuffer idxBuf, bool descend = false, DeviceSequence sequence = nullptr);
/**
 * @brief wait sequence completed
 * 1. If sequence is not submitted this function would return immediately
 * 2. If sequence is submitted this function would wait just like waitFence
 * @param device GPDevice 
 * @param sequence sequence with runing
 */
void AMAZING_EXPORT waitUntilCompleted(GPDevice* device, DeviceSequence sequence);
/**
 * @brief [Deprecated] convert YUV to RGB Texture
 * There will be a general convert function for colorspace transfer.
 * @param device GPDevice
 * @param yTex Y-Channel
 * @param uvTex UV-Channel
 * @param rgbaTex Dst Texture
 * @param transform transform matrix
 * @param sequence sequence with recording
 */
void AMAZING_EXPORT convertYuvToRgb(GPDevice* device, DeviceTexture yTex, DeviceTexture uvTex, DeviceTexture rgbaTex, const float transform[4][4] = defaultTransform, DeviceSequence sequence = nullptr);
/**
 * @brief get "friend" texture for specific device type
 * texture must be created with share texture 
 * Now only support between OpenGL ES Backend and Metal Backend
 * PS: in MacOS, getFriendTexture does not return a "shared texture" but return a "new texture" with same data
 * this "new texture" is not sync with source texture.
 * @param device dst device
 * @param texture source texture 
 * @return DeviceTexture 
 */
DeviceTexture AMAZING_EXPORT getFriendTexture(RendererDevice* device, DeviceTexture texture);
DeviceTexture AMAZING_EXPORT getFriendTexture(ComputerDevice* device, DeviceTexture texture);
/**
 * @brief 提交缓冲区指令至GPU执行 | Submit the commands to gpu for execution
 * 只对于GL后端有实际作用，对非GL后端，不存在缓冲区，指令提交至GPU与Sequence的提交是一致的 | For only GL backends has a practical effect, for non-GL backends, the submission of commands is same as the submission of Sequence.
 * @param device dst device
 */
void AMAZING_EXPORT flushCommands(RendererDevice* device);
/**
 * @brief Auto Binding Wraaper For Device 
 * device->bind()
 * ...
 * device->unbind()
 * 
 * is same as 
 * 
 * RendererDeviceBindWrapper(device)
 * ...
 */
class RendererDeviceBindWrapper
{
public:
    RendererDeviceBindWrapper(RendererDevice* device)
    {
        if (m_device)
        {
            m_device->bind();
        }
    }
    virtual ~RendererDeviceBindWrapper()
    {
        if (m_device)
        {
            m_device->unbind();
        }
    }

    RendererDeviceBindWrapper(RendererDeviceBindWrapper&& p) noexcept = default;
    RendererDeviceBindWrapper& operator=(RendererDeviceBindWrapper&& p) noexcept = default;

    RendererDeviceBindWrapper(const RendererDeviceBindWrapper& p) = delete;
    RendererDeviceBindWrapper& operator=(const RendererDeviceBindWrapper& p) = delete;

protected:
    RendererDevice* m_device = nullptr;
};
/**
 * @brief Auto Binding&StateSync Wraaper For Device 
 * device->bind()
 * device->syncState()
 * device->pushState()
 * ...
 * device->popState()
 * device->unbind()
 * 
 * is same as 
 * 
 * RendererDeviceStateWrapper(device)
 * ...
 */
class RendererDeviceStateWrapper : RendererDeviceBindWrapper
{
public:
    RendererDeviceStateWrapper(RendererDevice* device)
        : RendererDeviceBindWrapper(device)
    {
        if (m_device)
        {
            m_device->syncState();
            m_device->pushState();
        }
    }
    virtual ~RendererDeviceStateWrapper() override
    {
        if (m_device)
        {
            m_device->popState();
        }
    }

    RendererDeviceStateWrapper(RendererDeviceStateWrapper&& p) noexcept = default;
    RendererDeviceStateWrapper& operator=(RendererDeviceStateWrapper&& p) noexcept = default;

    RendererDeviceStateWrapper(const RendererDeviceStateWrapper& p) = delete;
    RendererDeviceStateWrapper& operator=(const RendererDeviceStateWrapper& p) = delete;
};
/**
 * @brief Auto Binding MainContext Wraaper For Device 
 * device->bind(true)
 * ...
 * device->unbind()
 * 
 * is same as 
 * 
 * RendererDeviceBindMainContextWrapper(device)
 * ...
 */
class RendererDeviceBindMainContextWrapper
{
public:
    RendererDeviceBindMainContextWrapper()
    {
        RendererDevice::bindMainContext();
    }

    ~RendererDeviceBindMainContextWrapper()
    {
        RendererDevice::unbindMainContext();
    }

    RendererDeviceBindMainContextWrapper(RendererDeviceBindMainContextWrapper&& p) noexcept = default;
    RendererDeviceBindMainContextWrapper& operator=(RendererDeviceBindMainContextWrapper&& p) noexcept = default;

    RendererDeviceBindMainContextWrapper(const RendererDeviceBindMainContextWrapper& p) = delete;
    RendererDeviceBindMainContextWrapper& operator=(const RendererDeviceBindMainContextWrapper& p) = delete;

protected:
    RendererDevice* m_device = nullptr;
};

DeviceTexture AMAZING_EXPORT getFriendTexture(RendererDevice* device, DeviceTexture texture);
DeviceTexture AMAZING_EXPORT getFriendTexture(ComputerDevice* device, DeviceTexture texture);

#if AMAZING_PLATFORM == AMAZING_MACOS
/**
 * @brief get "mapping" texture for specific device type
 * texture must be created with share texture 
 * Now only support between OpenGL ES Backend and Metal Backend
 * PS: in MacOS, mapFriendTexture return a "shared texture" but type is TextureRectangle which is not equal to Texture2D
 * In IOS, mapFriendTexture is same as getFriendTexture
 * @param device dst device
 * @param texture source texture 
 * @return DeviceTexture 
 */
DeviceTexture AMAZING_EXPORT mapFriendTexture(RendererDevice* device, DeviceTexture texture);
DeviceTexture AMAZING_EXPORT mapFriendTexture(ComputerDevice* device, DeviceTexture texture);
#endif

#if AMAZING_PLATFORM == AMAZING_IOS || AMAZING_PLATFORM == AMAZING_MACOS
/**
 * @brief create a CVPixelBuffer on Apple device
 * @param width buffer widthe
 * @param height buffer height
 * @param format CVPixelBuffer format
 * @param data reference to the data
 */
NativeBuffer AMAZING_EXPORT createCVPixelBuffer(int width, int height, int pitch, OSType format, const void* data);
#endif

} // namespace Utils

NAMESPACE_AMAZING_ENGINE_END

#endif /* Utils_h */
