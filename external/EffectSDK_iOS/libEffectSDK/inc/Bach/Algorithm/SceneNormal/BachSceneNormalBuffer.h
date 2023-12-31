#ifdef __cplusplus
#ifndef BACH_SCENE_NORMAL_BUFFER_H
#define BACH_SCENE_NORMAL_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SceneNormalInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;                        //the width of the mask
    int height = 0;                       //the height of the mask
    AmazingEngine::UInt8Vector mask_data; //mask
};

class BACH_EXPORT SceneNormalBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<SceneNormalInfo> m_sceneNormalInfo;

    BachBuffer* _clone() const override
    {
        if (m_sceneNormalInfo.isNull())
        {
            return nullptr;
        }
        SceneNormalBuffer* buffer = new SceneNormalBuffer();
        buffer->m_sceneNormalInfo = new SceneNormalInfo();
        SceneNormalInfo* src = static_cast<SceneNormalInfo*>(m_sceneNormalInfo.get());
        SceneNormalInfo* dst = static_cast<SceneNormalInfo*>(buffer->m_sceneNormalInfo.get());
        dst->width = src->width;
        dst->height = src->height;
        dst->mask_data = src->mask_data.copy();
        return buffer;
    }
};
NAMESPACE_BACH_END
#endif
#endif