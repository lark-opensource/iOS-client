#ifdef __cplusplus
#ifndef BACH_FACE_VERIFY_BUFFER_H
#define BACH_FACE_VERIFY_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Bach/Algorithm/Face/BachFaceBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

enum class FACE_TRACKING_STATUS
{
    BEF_FACE_TRACKING_STATUS_UNKNOWN = 0,
    BEF_FACE_TRACKING_STATUS_APPEAR = 1,   // New, unknown feature
    BEF_FACE_TRACKING_STATUS_REGISTER = 2, // New, known features
    BEF_FACE_TRACKING_STATUS_TRACK = 3,
    BEF_FACE_TRACKING_STATUS_MISS = 4
};

class BACH_EXPORT FaceVerifyInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::FloatVector features;
    AmazingEngine::SharePtr<Face106> m_face106;
    int ID = -1;
    AmazingEngine::Rect rect;
    FACE_TRACKING_STATUS m_faceStatus;
    std::string m_modelVersion;
};

class BACH_EXPORT FaceVerifyBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<FaceVerifyInfo>> m_faceVerifyInfos;
    std::vector<AmazingEngine::SharePtr<FaceVerifyInfo>> m_dynamicInfos;
    bool needUpdate = false;
    int m_validFaceNum = 0;
    int m_dynamicFaceNum = 0;
};

NAMESPACE_BACH_END
#endif
#endif