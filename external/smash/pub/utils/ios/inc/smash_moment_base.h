#ifndef _SMASH_MOMENT_BASE_H_
#define _SMASH_MOMENT_BASE_H_

#include "tt_common.h"

#include <stdint.h>

/**
 * @brief 剪同款编辑页裁剪的信息
 *
 * @note 默认 0,0,1,1
 */
typedef struct VideoTempRecCropInfo {
  float upperLeftX = 0.0;
  float upperLeftY = 0.0;
  float lowerRightX = 1.0;
  float lowerRightY = 1.0;
} VideoTempRecCropInfo;

typedef struct VideoSegType {
  // 素材id
  int materialID;
  // 素材开始时间, 图片 -1, 视频 (ms)
  float startTime;
  // 素材结束时间, 图片 -1, 视频 (ms)
  float endTime;
  // fragment_id    // 跟模板关联的片段信息；
                    // 老影集：nullptr
                    // 新影集：1,2,3,4
                    // 剪同款：payload_9D9F630B-B418-47A7-8D51-72FBD144E7D5
  const char* fragment_id;
  // 裁剪信息
  VideoTempRecCropInfo crop;
}VideoSegType;

/**
 * @brief 返回的结构体
 *
 */
struct VideoTempRecType {
  int64_t templateID;
  int templateSource;                    // 1: 剪同款； 2: 影集；
  VideoSegType* segs;
  int numSeq;
  const char* zipURL; //
};

typedef struct AIMoment{
  char* momentID; // moment id
  const char* momentType;
  char* title;
  int coverId;
  int version;
  int * materialIDs;                      // 素材的id
  int numMaterial;                         // material的数量
  int64_t templateID;                      // 有代表 精品模板id or 外部配置的模板id；是否为精品模板id？bool
  int momentSource;                      // 0: 常规moment or 外部配置moment 1：精品moment
  const char* effectID;
  const char* extra;
}AIMoment;

typedef enum MomentTagType
{
  MOMENT_TAG_C1 = 4,
  MOMENT_TAG_C2 = 14,
  MOMENT_TAG_C3 = 24,
  MOMENT_TAG_VIDEO = 410,
} MomentTagType;

typedef enum MomentSourceType
{
  MOMENT_SOURCE_LOCAL = 1,
  MOMENT_SOURCE_ELABR = 5,
  MOMENT_SOURCE_NORMAL = 15,
} MomentSourceType;

typedef struct MomentTagInfo
{
  int64_t id;
  char* name;
  int type; // c1,c2,video_cls
  float confidence; // Tag 的置信度
} MomentTagInfo;

// 人脸相关struct
typedef struct MomentFaceInfo
{
  int64_t faceId;
  AIRect rect; // 代表面部的矩形区域
  float yaw;          // 水平转角,真实度量的左负右正
  float pitch;        // 俯仰角,真实度量的上负下正
  float roll;         // 旋转角,真实度量的左负右正
  float realFaceProb; // 真脸的概率
  float quality;      // 预测人脸的质量分数，范围【0，100】之间
  float boyProb;     // 预测为男性的概率值，值范围【0.0，1.0】之间
  float age;          // 预测的年龄值， 值范围【0，100】之间
  float happyScore;  // 预测的微笑程度，范围【0，100】之间
  // todo 本期需求不会添加，下个版本还有可能添加，一般都是单个 int, float
} MomentFaceInfo;

typedef struct MomentScoreInfo
{                        // 打分
  float time; // ms
  float score;           // 最终得分
  float faceScore;      // 人脸得分
  float qualityScore;   // 综合质量得分
  float sharpnessScore; // 清晰度得分
  float meanLessScore;  // 无意义模型得分
  float portraitScore; // 人像得分
} MomentScoreInfo;

typedef struct MomentMetaInfo
{
  // 基础信息
  int64_t size;    // 图片大小
  int width;       // 图片宽
  int height;      // 图片高，ratio可以由width/height得到
  int orientation; // 图片旋转角
  float duration;  // 素材的持续时长（仅视频）(ms)
  // 相机路径信息
  char* imgPath; // 图片路径
  bool isCamera; // 是否相机拍摄
   // 地理信息
  char* location; // 具体城市名：国家-省-城市，"%s_%s_%s", UTF-8编码  TODO：是否需要地图SDK？@zhongjie @zhizhao

  // 时间信息
  int64_t shotTime;   // 拍摄时间 (s)
  int64_t createTime; // 创建时间 (s)
  int64_t modifyTime; // 修改时间 (s)
} MomentMetaInfo;

typedef struct MomentCotentInfo
{
  // tag信息, from BIM
  MomentTagInfo* momentTags; // C1、C2、视频分类Tag
  int numTags;                  // Tag的数目

 // 人脸属性信息，from BIM
  MomentFaceInfo* faceFeatures; // 人脸特征
  int numFaces;                            // 人脸数目

  // 打分信息，from BIM
  MomentScoreInfo totalScoreInfo; // 素材的总体打分信息
  MomentScoreInfo* scoreInfos; // 素材的逐帧打分信息
  int numScoreInfos;

 // 审核，from BIM
  bool isPorn;
  bool isLeader;

  // 人脸识别id信息，from CIM
  int64_t* peopleID; // 识别人id
  int numPeople;      // 被识别出人的数目（聚类里人脸大于一定数目）

  // 去重id信息，from CIM
  int64_t simID; // 去重id
} MomentCotentInfo;

typedef struct MomentMaterialInfo
{
  int materialID;                      // 素材id
  MomentMetaInfo metaInfo; // 素材meta
  MomentCotentInfo contentInfo; // 素材content_info
} MomentMaterialInfo;


typedef struct MomentUserInfo
{
  char* base;    // 用户常驻地：具体城市名，"%s_%s_%s", 国家-省-城市，UTF-8编码
  float age;      // 用户年龄
  float boyProb; // 用户性别                   // 需要梳理还有哪些
} MomentUserInfo;

typedef struct MomentTemplatePair {
  char* momentID;        // moment id（只包含这次AIM后出现momentID）
  int momentSource;      // moment source
  int64_t templateID;    // template id（latest Used）
} MomentTemplatePair;

typedef struct VideoTempRecExtra {
  int coverID;              // 封面ID
  char* curMomentID;          // 当前MomentID
  MomentTemplatePair* usedPairs; // Moment Template Pair的数组指针
  int numUsedPairs;             // Moment Template Pair的长度
} VideoTempRecExtra;

typedef struct MomentInfo
{
  // 必须
  MomentMaterialInfo* materialInfos;
  int numMaterials; // n_material_info: 对于AIM模块是全部相册图片数， 对于TIM来说是Momnent里的图片数
  // 拓展
  int64_t templateID;     // template id(主要为模板反向推荐素材使用)
  MomentUserInfo userInfo; // 用户信息

  // 拓展0629
  VideoTempRecExtra* tempRecExtra;  // 推荐的额外输入
} MomentInfo;

#endif // _SMASH_MOMENT_BASE_H_
