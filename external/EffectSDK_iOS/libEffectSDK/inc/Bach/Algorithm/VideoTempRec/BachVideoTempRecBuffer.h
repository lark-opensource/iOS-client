#ifdef __cplusplus
#ifndef BACH_VIDEO_TEMP_REC_BUFFER_H
#define BACH_VIDEO_TEMP_REC_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT VideoSegmentInfo
{
public:
    std::string fragment_id;
    int materialId;
    float startTime = -1;
    float endTime = -1;
    AmazingEngine::FloatVector boundingBox;
};

class BACH_EXPORT VideoTempRecInfo : public AmazingEngine::RefBase
{
public:
    int64_t templateId;
    int templateSource;
    std::vector<VideoSegmentInfo> segments;
    std::string zipUrl;
};

class BACH_EXPORT VideoTempRecBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<VideoTempRecInfo>> m_TempRecInfos;
};

NAMESPACE_BACH_END
#endif
#endif