//
//  AWEMusicCollectionData.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/6.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEMusicCollectionData.h"

#import "ACCMusicCollectionFeedModel.h"
#import "ACCVideoMusicCategoryModel.h"

@implementation AWEMusicCollectionData

- (instancetype)initWithMusicCollectionFeedModel:(ACCMusicCollectionFeedModel *)collectionFeedModel {
    self = [self initWithType:AWEMusicCollectionDataTypeMusicCollection];
    if (self) {
        _collectionFeed = collectionFeedModel;
    }
    return self;
}

- (instancetype)initWithMusicModel:(id)musicModel withType:(AWEMusicCollectionDataType)type {
    if (musicModel) {
        NSAssert([musicModel isKindOfClass:NSClassFromString(@"AWEMusicModel")], @"music model must be AWEMusicModel");
    }
    self = [self initWithType:type];
    if (self) {
        _music = (id<ACCMusicModelProtocol>)musicModel;
    }
    return self;
}

- (instancetype)initWithCategoryArray:(NSArray<ACCVideoMusicCategoryModel *> *)categoryArray {
    self = [self initWithType:AWEMusicCollectionDataTypeCategory];
    if (self) {
        _categoryList = [categoryArray copy];
    }
    return self;
}

- (instancetype)initWithMusicArray:(NSArray<id<ACCMusicModelProtocol>> *)musicArray {
    self = [self initWithType:AWEMusicCollectionDataTypeMusicArray];
    if (self) {
        _musicList = [musicArray copy];
    }
    return self;
}

- (instancetype)initWithType:(AWEMusicCollectionDataType)type {
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}

// Init with DynamicPatch
- (instancetype)initWithDynamicModel:(AWEDynamicPatchModel *)dynamicModel
{
    self = [self initWithType:AWEMusicCollectionDataTypeDynamic];
    if (self) {
        _dynamicPatchModel = dynamicModel;
    }
    return self;

}

- (instancetype)initWithRecommendedVideosModel:(id<ACCSearchMusicRecommendedVideosModelProtocol>)recommendModel {
    self = [self initWithType:AWEMusicCollectionDataTypeRecommendVideo];
    if (self) {
        _recommendModel = recommendModel;
    }
    return self;
}

@end
