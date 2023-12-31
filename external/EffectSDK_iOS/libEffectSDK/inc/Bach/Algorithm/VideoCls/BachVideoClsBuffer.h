#ifdef __cplusplus
#ifndef BACH_VIDEO_CLS_BUFFER_H
#define BACH_VIDEO_CLS_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT VideoClsInfo : public AmazingEngine::RefBase
{
public:
    int id;           //class id
    float confidence; //class confidence
    float thres;      //class thres
    bool satisfied = false;
    std::string name;
};

class BACH_EXPORT VideoClsBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<VideoClsInfo>> m_videoClsInfos;
};

NAMESPACE_BACH_END
#endif
#endif