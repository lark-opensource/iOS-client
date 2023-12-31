#ifdef __cplusplus
#ifndef BACH_FOREHEAD_SEG_BUFFER_H
#define BACH_FOREHEAD_SEG_BUFFER_H
#include "Bach/Base/BachAlgorithmBuffer.h"
#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/Math/AMGMatrix4x4.h"
NAMESPACE_BACH_BEGIN

class BACH_EXPORT ForeheadSegInfo : public AmazingEngine::RefBase
{
public:
    int face_id;                          //人脸id
    int mask_width;                       //算法返回图像的宽
    int mask_height;                      //算法返回图像的高
    int image_width;                      //输入图形的宽
    int image_height;                     //输入图形的高
    AmazingEngine::Matrix4x4f mvp_matrix; //仿射变换矩阵
    AmazingEngine::UInt8Vector mask_data; // 算法返回图像数据,RGBA
};

class BACH_EXPORT ForeheadSegBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<ForeheadSegInfo>> m_infos;
};

NAMESPACE_BACH_END
#endif

#endif