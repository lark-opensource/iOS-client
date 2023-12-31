//
//  ACCImportVideoEditAdapter.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/9/15.
//

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"

FOUNDATION_EXTERN CGFloat kACCPhotoClipMaxSeconds;

@class AWEAssetModel;

@interface ACCImportVideoEditAdapter : NSObject

// 专门用于视频素材添加导入场景创建VideoData，导入场景后续可以下沉至此类

#pragma mark - 单轨道

// 创建单轨多段videoData
+ (ACCEditVideoData *)createNormalVideoDataWithSourceAssetArray:(NSArray<AWEAssetModel *> * _Nonnull)sourceAssetArray cahceDirPath:( NSString * _Nonnull)dirPath;

+ (ACCEditVideoData *)createNormalVideoDataWithSourceAssetArray:(NSArray<AWEAssetModel *> * _Nonnull)sourceAssetArray isLimitDuration:(BOOL)isLimitDuration isReset:(BOOL)isReset cacheDirPath:( NSString * _Nonnull)dirPath;


#pragma mark - 多轨道

// 创建多轨的VideoData
+ (ACCEditVideoData *)createMultiTrackNormalVideoDataWithMainTrackAssetArray:(NSArray<AWEAssetModel *> * _Nonnull)mainAssetArray
                                                          subTrackAssetArray:(NSArray<AWEAssetModel *> * _Nonnull)subAssetArray
                                                                cahceDirPath:( NSString * _Nonnull)dirPath;

@end
