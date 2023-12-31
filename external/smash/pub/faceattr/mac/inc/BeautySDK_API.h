#ifndef BeautySDK_API_hpp
#define BeautySDK_API_hpp

#include "FaceSDK_API.h"

#define AI_MAX_BEAUTY_STRING_LEN 32
#define AI_BEAUTY_ATTR_NUM 32
#define AI_BEAUTY_WITH_V3 0x80000000
typedef void *BeautyHandle;  ///  人脸属性检测句柄

typedef struct AIFaceBeautyBase {
  char category[AI_MAX_BEAUTY_STRING_LEN];  /// 属性类别, 目前支持： "face",
                                            /// "facelong", "eye", "jaw",
                                            /// "facewidth", "facesmooth",
                                            /// "nosewidth", "forehead"
  float label;  /// 属性值范围皆为 0.0 - 1.0 之间, 0.5代表中间水平
                /// "face"          脸部整体胖瘦 0.0瘦 1.0胖
                /// "facelong"      脸部长短(不考虑额头) 0.0短 1.0长
                /// "eye"           眼睛大小 0.0小 1.0大
                /// "jaw"           下巴尖圆 0.0圆 1.0尖
                /// "facewidth"     脸部宽度 0.0上宽下窄 1.0上窄下宽
                /// "facesmooth"    脸部平滑 0.0圆滑 1.0凹陷
                /// "nosewidth"     鼻子宽度 0.0窄 1.0宽
                /// "forehead"      额头高低 0.0短 1.0长
                /// "chin"          下巴人中比例 0下巴长 1人中长
                /// "leyebag"/"reyebag"/"lwrinkle"/"rwrinkle" 眼袋和法令纹深浅，值越大，程度越重
                /// "faceratio"      二三庭比例 0-二庭短 1-二庭长
                /// "eyebrowdist"    眉眼距离 0-距离窄 1-距离宽
                /// "eyedist"        眼距  0-眼距宽    1-眼距窄
                /// "eyeshape"       眼长  0-眼睛偏圆  1-眼睛偏细长
                /// "mouthwidth"     嘴宽 值越大，嘴越宽
  
  float score;  /// 属性的置信度, 0.0 - 1.0 之间, 值越大置信度越高
                /// 单帧置信度主要与脸部角度相关, 脸越正, 置信度越高
                /// 视频中对于同一个ID, 置信度会逐渐升高,
} AIFaceBeautyBase;

typedef struct AIFaceBeauty {
  AIFaceBeautyBase p_attributes[AI_BEAUTY_ATTR_NUM];
  int attribute_count;
} AIFaceBeauty, *PtrAIFaceBeauty;

AILAB_EXPORT
int FS_CreateFaceBeautyHandler(  /// 为提高速度, 不需要每帧都进行检测,
                                 /// config值代表每几帧执行一次属性模型, 推荐为4
    unsigned int config,  /// config | AI_BEAUTY_WITH_V3调用包含第三期属性的模型
    const char *param_path,
    BeautyHandle *handle);

AILAB_EXPORT
int FS_CreateFaceBeautyHandlerFromBuf(  /// 为提高速度, 不需要每帧都进行检测,
                                        /// config值代表每几帧执行一次属性模型,
                                        /// 推荐为4
    unsigned int config,  /// config | AI_BEAUTY_WITH_V3调用包含第三期属性的模型
    const char *param_buf,
    unsigned int param_buf_len,
    BeautyHandle *handle);

AILAB_EXPORT
int FS_DoFaceBeautyPredict(BeautyHandle handle,
                           const unsigned char *image,
                           PixelFormatType pixel_format,
                           int image_width,
                           int image_height,
                           int image_stride,
                           const AIFaceInfoBase *p_face_array,
                           int face_count,
                           AIFaceBeauty *p_attributes_array);

AILAB_EXPORT
void FS_ReleaseFaceBeautyHandle(BeautyHandle handle);

#endif /* BeautySDK_API_hpp */
