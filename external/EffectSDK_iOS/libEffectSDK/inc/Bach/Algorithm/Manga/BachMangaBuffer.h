#ifdef __cplusplus
#ifndef BACH_MANGA_BUFFER_H
#define BACH_MANGA_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT MangaInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::UInt8Vector data;     // 图像数据
    int width = 0;                       // 图像宽
    int height = 0;                      // 图像高
    int channels = 0;                    // 图像通道
    AmazingEngine::FloatVector matrix;   // 算法原始数据
    AmazingEngine::Matrix4x4f affineMat; // 仿射变换矩阵
    int type = 0;                        // 检测类型 0-boy, 1-girl, 2-cat, 3-dog

    int imageWidth;  // 原图宽
    int imageHeight; // 原图高
};

class BACH_EXPORT MangaBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<MangaInfo>> m_mangaInfos;
    AmazingEngine::SharePtr<MangaInfo> m_bgMangaInfo;
};

NAMESPACE_BACH_END
#endif
#endif