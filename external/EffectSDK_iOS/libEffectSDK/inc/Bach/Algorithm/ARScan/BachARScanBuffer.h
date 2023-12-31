#ifdef __cplusplus
#ifndef _BACH_AR_SCAN_BUFFER_H_
#define _BACH_AR_SCAN_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN
class BACH_EXPORT ARScanInfo : public AmazingEngine::RefBase
{
public:
    int status = -1; //status: 算法的状态，总共4种状态: PARAMETER_ERROR -1, SEARCHING 0, MATCHING 1, RACKING(succeed) 2
    std::string scannable_name = "";
    AmazingEngine::FloatVector target_area; // [tlx, tly, trx, try, blx, bly, brx, bry]
};

class BACH_EXPORT ARScanBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<ARScanInfo>> m_arscanInfo;
};

NAMESPACE_BACH_END
#endif
#endif