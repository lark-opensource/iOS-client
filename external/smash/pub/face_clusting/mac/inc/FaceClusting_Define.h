#ifndef FaceClusting_Define_H
#define FaceClusting_Define_H

typedef void* FaceClustingHandle;

// Note: Confilct with  Food Cls
// FaceClusting -->FC

typedef enum FC_ParamType
{
  RecognitionfThreshold = 1, //人脸识别阈值，值越大，召回越高，默认值0.3
  FeatureDim = 2,            //特征长度,默认为128
  ClustingThreshold =
    3, //聚类时，两个临时类被合并的距离阈值
       //越小约准，但是越不全，容易漏掉同一个人差异比较大的脸,越大越全，但是越不准，容易把不是同一人但是相似的脸聚进来
       // 默认值dist_threshold = 1.15 * 0.82 = 0.943;
  LinkageType = 4,         // 链接方法,默认AvgLinkage
  DistanceType = 5,        // 距离度量方法 默认EUCLIDEAN
  HP1 = 6,                 // 超参1, 默认0.895;
  HP2 = 7,                 // 超参2,默认0.29
  HP3 = 8,                 // 超参3,默认0.885 用于分批聚类的批合并
  HP4 = 9,                 // 超参4,默认0.29  用于分批聚类的批合并
  ClustingThreshold2 = 10, // 第二距离阈值 默认0.943,用于分批聚类的批合并
  BatchSize = 11,          // 分批聚类的批尺寸, 默认2000, 越小内存占用越小, 但通常速度越慢.
  MaxMergeRound = 12, // 分批聚类最大的合并次数，默认值为10，最小值为1，值越大，速度越慢，精度越高
} FC_ParamType;

typedef enum FC_DistanceType
{
  EUCLIDEAN = 1,      //欧式距离
  COSINE = 2,         //余弦距离, 默认值
  BHATTACHARYYAH = 3, //巴氏距离
} FC_DistanceType;

typedef enum FC_LinkType
{
  AVERAGE_LINKAGE = 1,  /* choose average distance  default*/
  CENTROID_LINKAGE = 2, /* choose distance between cluster centroids */
  COMPLETE_LINKAGE = 3, /* choose maximum distance */
  SINGLE_LINKAGE = 4,   /* choose minimum distance */
} FC_LinkType;

#endif
