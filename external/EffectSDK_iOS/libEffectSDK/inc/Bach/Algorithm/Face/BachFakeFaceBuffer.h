#ifdef __cplusplus
#ifndef BACH_FAKE_FACE_BUFFER_H
#define BACH_FAKE_FACE_BUFFER_H
#include "Bach/Algorithm/Face/BachFaceBuffer.h"
NAMESPACE_BACH_BEGIN
class BACH_EXPORT FakeFaceBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<Face106>> m_fakeFaceBaseInfos;
    FakeFaceBuffer* _clone() const override
    {
        return nullptr;
    }
};
NAMESPACE_BACH_END
#endif //BACH_FAKE_FACE_BUFFER_H

#endif