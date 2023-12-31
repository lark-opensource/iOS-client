#ifdef __cplusplus
#ifndef BACH_FACE_NEW_LANDMARK_BUFFER_H
#define BACH_FACE_NEW_LANDMARK_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT FaceNewLandmarkInfo : public AmazingEngine::RefBase
{
public:
    int faceID;
    AmazingEngine::Vec2Vector points; // face outline point
};

class BACH_EXPORT FaceNewLandmarkBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FaceNewLandmarkInfo>> m_faces;

    virtual BachBuffer* _clone() const override
    {
        if (m_faces.empty())
        {
            return nullptr;
        }
        FaceNewLandmarkBuffer* buffer = new FaceNewLandmarkBuffer();
        buffer->m_faces.resize(m_faces.size());
        for (int i = 0; i < m_faces.size(); ++i)
        {
            FaceNewLandmarkInfo* src = static_cast<FaceNewLandmarkInfo*>(m_faces[i].get());
            buffer->m_faces[i] = new FaceNewLandmarkInfo();
            FaceNewLandmarkInfo* dst = static_cast<FaceNewLandmarkInfo*>(buffer->m_faces[i].get());
            dst->faceID = src->faceID;
            dst->points = src->points.copy();
        }

        return buffer;
    }
};

NAMESPACE_BACH_END
#endif
#endif