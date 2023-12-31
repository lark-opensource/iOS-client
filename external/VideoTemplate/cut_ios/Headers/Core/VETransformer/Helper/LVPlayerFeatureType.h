//
//  LVPlayerFeatureType.h
//  Pods
//
//  Created by kevin gao on 2019/12/24.
//

#ifndef LVPlayerFeatureType_h
#define LVPlayerFeatureType_h

typedef NS_ENUM(NSUInteger, LVPlayerFeatureType) {
    LVPlayerFeatureTypeFlipX = 0,       //水平翻转
    LVPlayerFeatureTypeFlipY = 1,       //垂直翻转
    LVPlayerFeatureTypeBeauty = 2,      //美颜--磨皮
    LVPlayerFeatureTypeReshape = 3,     //美颜--瘦脸
    LVPlayerFeatureTypeChroma = 4,      //色度抠图
    LVPlayerFeatureTypeSeparatedSound = 5, // 音频分离
    LVPlayerFeatureTypeStretchLeg = 6,  //美体--长腿
};

#endif /* LVPlayerFeatureType_h */
