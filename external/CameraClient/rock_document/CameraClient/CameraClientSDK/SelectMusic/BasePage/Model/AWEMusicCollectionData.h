//
//  AWEMusicCollectionData.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/6.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CreationKitArch/ACCMusicModelProtocol.h>
#import "ACCSearchMusicRecommendedVideosModelProtocol.h"

@class AWEDynamicPatchModel;
@class ACCMusicCollectionFeedModel;
@class ACCVideoMusicCategoryModel;

typedef NS_ENUM(NSUInteger, AWEMusicCollectionDataType) {
    AWEMusicCollectionDataTypeCategory,
    AWEMusicCollectionDataTypeMusicCollection,
    AWEMusicCollectionDataTypeMusicArray,
    AWEMusicCollectionDataTypeMusic,
    AWEMusicCollectionDataTypeChallenage,
    AWEMusicCollectionDataTypeSameStickerMusic,
    AWEMusicCollectionDataTypeFavEmpty,
    AWEMusicCollectionDataTypeProp,
    AWEMusicCollectionDataTypeMV,
    AWEMusicCollectionDataTypeUploadRecommend,
    AWEMusicCollectionDataTypeEmptyPlaceholder,
    AWEMusicCollectionDataTypeSearchEmpty,
    AWEMusicCollectionDataTypeRecommendVideo = 998,
    AWEMusicCollectionDataTypeDynamic = 999,
    AWEMusicCollectionDataTypeExportAudioSection = 1000,
    AWEMusicCollectionDataTypeLocalAudioAuthSection = 1001,
    AWEMusicCollectionDataTypeLocalAudioEmptySection = 1002,
    AWEMusicCollectionDataTypeAudioManageSection = 1003,
    AWEMusicCollectionDataTypeLocalMusicListSection = 1004,
    AWEMusicCollectionDataTypeLocalAudioFooterAuthSection = 1005,
};

@interface AWEMusicCollectionData : NSObject

@property (nonatomic, assign) AWEMusicCollectionDataType type;

@property (nonatomic, copy) NSArray<ACCVideoMusicCategoryModel *> *categoryList;

@property (nonatomic, copy) id<ACCMusicModelProtocol> music;

@property (nonatomic, strong) ACCMusicCollectionFeedModel *collectionFeed;

@property (nonatomic, copy) NSArray<id<ACCMusicModelProtocol>> *musicList;

@property (nonatomic, strong) AWEDynamicPatchModel *dynamicPatchModel;

@property (nonatomic, strong) id<ACCSearchMusicRecommendedVideosModelProtocol> recommendModel;

// Init with Music Collection Feed Model.
- (instancetype)initWithMusicCollectionFeedModel:(ACCMusicCollectionFeedModel *)collectionFeedModel;
// Init with Music Model.
- (instancetype)initWithMusicModel:(id)musicModel withType:(AWEMusicCollectionDataType)type;
// Init with category array.
- (instancetype)initWithCategoryArray:(NSArray<ACCVideoMusicCategoryModel *> *)categoryArray;
// Init with recommend music array.
- (instancetype)initWithMusicArray:(NSArray<id<ACCMusicModelProtocol>> *)musicArray;

- (instancetype)initWithType:(AWEMusicCollectionDataType)type;
// Init with DynamicPatch
- (instancetype)initWithDynamicModel:(AWEDynamicPatchModel *)dynamicModel;

//recommedVideos
- (instancetype)initWithRecommendedVideosModel:(id<ACCSearchMusicRecommendedVideosModelProtocol>)recommendModel;

@end
