/**
 * @file PropertyBlock.h
 * @author zhaochenxiang (zhaochenxiang@bytedance.com)
 * @brief PropertyBlock describes RendererDevice's uniform data inputs
 * @version 1.0.0
 * @date 2019-12-10
 * @copyright Copyright (c) 2019 Bytedance Inc. All rights reserved.
 */
#pragma once

#include <unordered_map>

#include "Gaia/AMGInclude.h"
#include "Runtime/RenderLib/RendererDeviceTypes.h"
#include "Gaia/AMGRefBase.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief PropertyBlock describes RendererDevice's uniform data inputs
 * T Property's key in PropertyBlockBase, could be String(Uniform Name) or Int(Built-In Uniform Key ). 
 */
template <class T>
class PropertyBlockBase : public RefBase
{
public:
    /**
     * @brief [DEPRECATED] Uniform Type
     */
    enum
    {
        NONE,
        TEX_2D,
        TEX_3D,
        TEX_CUBE,
        BUFFER_UNIFORM,
        BUFFER_STORAGE,
    };

private:
    std::unordered_map<T, SharePtr<DeviceProperty>> m_DeviceProperties;
    bool m_dirtyRestted = false;

public:
    /**
     * @brief [DEPRECATED] Get SymbolType according to uniform data's row & column cound and texture type
     * @param rows uniform data's row count
     * @param cols uniform data's column count
     * @param texType uniform data's texture type
     * @return SymbolType 
     */
    SymbolType calSymbolType(uint8_t rows, uint8_t cols, uint32_t texType = NONE)
    {
        SymbolType st = SymbolType::INVALID;
        if (rows == 1 && cols == 1)
            st = SymbolType::FLOAT;
        else if (rows == 1 && cols == 4)
            st = SymbolType::FLOAT_VEC4;
        else if (rows == 4 && cols == 4)
            st = SymbolType::FLOAT_MAT4;
        else if (rows == 1 && cols == 3)
            st = SymbolType::FLOAT_VEC3;
        else if (rows == 1 && cols == 2)
        {
            if (texType == NONE)
                st = SymbolType::FLOAT_VEC2;
            else if (texType == TEX_2D)
                st = SymbolType::SAMPLER_2D;
            else if (texType == TEX_CUBE)
                st = SymbolType::SAMPLER_CUBE;
            else if (texType == BUFFER_UNIFORM)
                st = SymbolType::UNIFORM_BLOCK;
            else if (texType == BUFFER_STORAGE)
                st = SymbolType::STORAGE_BLOCK;
            else
                aeAssert(false);
        }
        else
        {
            aeAssert(false);
        }
        return st;
    }
    /**
     * @brief Set property value
     * @param key Property's key in PropertyBlockBase
     * @param data Property's data
     * @param rows Property's row count
     * @param cols Property's column count
     * @param count Property's data count, for non-array property, this should be 1
     * @param texType Property's texture type
     * @param enumKey Property's enumKey, if set to -1, name would be used instead.
     * @param name Property's name
     */
    void SetProperty(const int& key, const float* data, uint8_t rows, uint8_t cols, uint32_t count, uint32_t texType = NONE, int enumKey = -1, const char* name = nullptr)
    {
        if (nullptr == data || count <= 0)
            return;
        m_dirtyRestted = false;
        auto it = m_DeviceProperties.find(key);
        SymbolType st = calSymbolType(rows, cols, texType);
        if (it != m_DeviceProperties.end())
        {
            it->second->resetCount(count);
            it->second->resetType(st);
            it->second->setValue((void*)data);
            return;
        }
        SharePtr<DeviceProperty> newProperty = new DeviceProperty(name, st, count, enumKey, (void*)data);
        m_DeviceProperties.emplace(key, newProperty);
    }
    /**
     * @brief Set property value
     * @param name Property's name
     * @param data Property's data
     * @param rows Property's row count
     * @param cols Property's column count
     * @param count Property's data count, for non-array property, this should be 1
     * @param texType Property's texture type
     * @param enumKey Property's enumKey
     */
    void SetProperty(const String& name, const float* data, uint8_t rows, uint8_t cols, uint32_t count, uint32_t texType = NONE, int enumKey = -1)
    {
        if (nullptr == data || count <= 0)
            return;
        m_dirtyRestted = false;
        auto it = m_DeviceProperties.find(name);
        SymbolType st = calSymbolType(rows, cols, texType);
        if (it != m_DeviceProperties.end())
        {
            it->second->resetCount(count);
            it->second->resetType(st);
            it->second->setValue((void*)data);
            return;
        }
        SharePtr<DeviceProperty> newProperty = new DeviceProperty(name.c_str(), st, count, enumKey, (void*)data);
        m_DeviceProperties.emplace(name, newProperty);
    }
    /**
     * @brief Set property float value
     * @param name Property's name
     * @param val Property's float value
     * @param enumKey Property's enumKey
     */
    void SetFloat(const T& name, float val, int enumKey = -1)
    {
        SetProperty(name, &val, 1, 1, 1, NONE, enumKey);
    }
    /**
     * @brief Set property vec4 value
     * @param name Property's name
     * @param vec Property's vec4 value
     * @param enumKey Property's enumKey
     */
    void SetVector(const T& name, const Vector4f& vec, int enumKey = -1)
    {
        SetProperty(name, vec.GetPtr(), 1, 4, 1, NONE, enumKey);
    }
    /**
     * @brief Set Property matrix value
     * @param name Property's name
     * @param mat Property's matrix value
     * @param enumKey Property's enumKey
     */
    void SetMatrix(const T& name, const Matrix4x4f& mat, int enumKey = -1)
    {
        SetProperty(name, mat.GetPtr(), 4, 4, 1, NONE, enumKey);
    }
    /**
     * @brief Set Property transpose matrix value. Currently only works on Windows Angle
     * @param name Property's name
     * @param mat Property's matrix value
     * @param enumKey Property's enumKey
     */
    void SetTransposeMatrix(const String& name, const Matrix4x4f& mat, int enumKey = -1)
    {
#if AMAZING_PLATFORM == AMAZING_WINDOWS
        const float* data = mat.GetPtr();

        if (nullptr == data)
            return;

        m_dirtyRestted = false;
        auto it = m_DeviceProperties.find(name);
        if (it != m_DeviceProperties.end())
        {
            it->second->resetCount(1);
            it->second->resetType(SymbolType::FLOAT_MAT4_TRANSPOSE);
            it->second->setValue((void*)data);
            return;
        }
        SharePtr<DeviceProperty> newProperty = new DeviceProperty(name.c_str(), SymbolType::FLOAT_MAT4_TRANSPOSE, 1, enumKey, (void*)data);
        m_DeviceProperties.emplace(name, newProperty);
#endif
    }
    /**
     * @brief Set Property transpose matrix value. Currently only works on Windows Angle
     * @param key Property's key
     * @param mat Property's matrix value
     * @param enumKey Property's enumKey
     */
    void SetTransposeMatrix(const int& key, const Matrix4x4f& mat, int enumKey = -1)
    {
#if AMAZING_PLATFORM == AMAZING_WINDOWS
        const float* data = mat.GetPtr();

        if (nullptr == data)
            return;

        m_dirtyRestted = false;
        auto it = m_DeviceProperties.find(key);
        if (it != m_DeviceProperties.end())
        {
            it->second->resetCount(1);
            it->second->resetType(SymbolType::FLOAT_MAT4_TRANSPOSE);
            it->second->setValue((void*)data);
            return;
        }
        SharePtr<DeviceProperty> newProperty = new DeviceProperty(nullptr, SymbolType::FLOAT_MAT4_TRANSPOSE, 1, enumKey, (void*)data);
        m_DeviceProperties.emplace(key, newProperty);
#endif
    }
    /**
     * @brief Set Property texture value
     * @param name Property's name
     * @param texId Property's texture value
     * @param enumKey Property's enumKey
     */
    void SetTexture2D(const T& name, DeviceTexture texId, int enumKey = -1)
    {
        SetProperty(name, reinterpret_cast<const float*>(&texId), 1, 2, 1, TEX_2D, enumKey);
    }
    /**
     * @brief Set Property texture cube value
     * @param name Property's name
     * @param texId Property's texture cube value
     * @param enumKey Property's enumKey
     */
    void SetTextureCube(const T& name, DeviceTexture texId, int enumKey = -1)
    {
        SetProperty(name, reinterpret_cast<const float*>(&texId), 1, 2, 1, TEX_CUBE, enumKey);
    }
    /**
     * @brief Get DeviceProperty map
     * @return const std::unordered_map<T, SharePtr<DeviceProperty>>& 
     */
    const std::unordered_map<T, SharePtr<DeviceProperty>>& getDeviceProperties() const
    {
        return m_DeviceProperties;
    }
    /**
     * @brief Set property dirty
     * @param dirty dirty
     */
    void setPropertiesDirty(bool dirty)
    {
        if (m_dirtyRestted && !dirty)
        {
            return;
        }
        for (auto& cur : m_DeviceProperties)
        {
            cur.second->forceSetDirty(dirty);
        }

        m_dirtyRestted = !dirty;
    }

    /**
     * @brief Clear properties
     */
    void Clear()
    {
        m_DeviceProperties.clear();
    }
    /**
     * @brief destructor
     */
    ~PropertyBlockBase() = default;
};

/**
 * @brief String as PropertyBlock's key
 */
using PropertyBlockKeyStr = PropertyBlockBase<String>;
/**
 * @brief int as PropertyBlock's key
 */
using PropertyBlockKeyInt = PropertyBlockBase<int>;

NAMESPACE_AMAZING_ENGINE_END
