#ifdef __cplusplus
#ifndef BACH_FACE_MASK_BUFFER_H
#define BACH_FACE_MASK_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FaceMaskInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::UInt8Vector alpha;
    AmazingEngine::Rect bboxes;
    AmazingEngine::Vec2Vector kpts;
    AmazingEngine::Vec3Vector kpts3D;
    int mask_count;
    int width;
    int height;
    AmazingEngine::Vec3Vector rotation;
    AmazingEngine::Vec3Vector translate;
    int rotationStatus;
};

class BACH_EXPORT FaceMaskBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FaceMaskInfo>> m_faceMaskInfos;
};

NAMESPACE_BACH_END
#endif
#endif