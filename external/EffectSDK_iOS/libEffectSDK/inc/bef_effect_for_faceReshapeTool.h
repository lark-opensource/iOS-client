//
//  bef_effect_for_faceReshapeTool.h
//  AmazingEditor
//
//  Created by jianglinjun.0802 on 2020/8/3.

#ifdef AMAZING_EDITOR_SDK

#ifndef bef_effect_for_faceReshapeTool_h
#define bef_effect_for_faceReshapeTool_h

#include "bef_effect_public_define.h"
#include <vector>

BEF_SDK_API void bef_get_facereshapeV4_indices(std::vector<int>& re_indices);

BEF_SDK_API void bef_get_facereshapeV5_indices(std::vector<int>& re_indices);

BEF_SDK_API void bef_get_facereshapeV6_indices(std::vector<int>& re_indices);

BEF_SDK_API void bef_updateV5FaceMesh(const std::vector<float>& face_points, int width, int height,
                                    const std::vector<float>& lmfiveorganVec, const std::vector<float>& plasticineParams, int eyeType,
                                    std::vector<float>& basicMeshVertex, float yaw = 0.0f, float roll = 0.0f, float pitch = 0.0f);

BEF_SDK_API void bef_V6Interplation(const std::vector<float>& point_in, std::vector<float>& point_out, float yaw, float fwidht, float fheight);

BEF_SDK_API void bef_updateV4FaceMesh(const std::vector<float>& face_points, int width, int height, const std::vector<float>& lmfiveorganVec, const std::vector<float>& plasticineParams, int eyeType, std::vector<float>& basicMeshVertex, float yaw = 0.0f, float roll = 0.0f, float pitch = 0.0f);
#endif /* bef_effect_for_faceReshapeTool_h */

#endif
