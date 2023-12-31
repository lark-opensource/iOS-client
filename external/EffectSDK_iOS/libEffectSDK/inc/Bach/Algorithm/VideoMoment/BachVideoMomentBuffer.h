#ifdef __cplusplus
#ifndef BACH_VIDEO_MOMENT_BUFFER_H
#define BACH_VIDEO_MOMENT_BUFFER_H

#include "Bach/Base/BachBaseDefine.h"
#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT VideoMomentInfo : public AmazingEngine::RefBase
{
public:
    std::string momentId;
    std::string momentType;
    std::string title;
    int coverId;
    int version;
    std::vector<int> materialIDs;
    int64_t templateId;
    int momentSource;
    std::string effectId;
    std::string extra;
};

class BACH_EXPORT VideoMomentBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<VideoMomentInfo>> m_MomentInfos;
};

NAMESPACE_BACH_END

#endif

#endif