#ifdef __cplusplus
#ifndef BACH_PORN_CLS_BUFFER_H
#define BACH_PORN_CLS_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT PornClsBuffer : public BachBuffer
{
public:
    bool is_porn = false;
    float confidence = 0.0f;
};

NAMESPACE_BACH_END
#endif
#endif