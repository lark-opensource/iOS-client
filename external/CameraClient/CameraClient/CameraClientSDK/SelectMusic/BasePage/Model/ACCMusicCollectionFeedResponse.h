//
//  ACCMusicCollectionFeedResponse.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/4.
//  Copyright © 2018年 bytedance. All rights reserved.
//

@class ACCMusicCollectionFeedModel;
@class ACCVideoMusicCategoryModel;

#import <CreationKitInfra/ACCBaseApiModel.h>

@interface ACCMusicCollectionFeedResponse : ACCBaseApiModel

@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSArray<ACCMusicCollectionFeedModel *> *musicCollection;
@property (nonatomic, strong) NSNumber *cursor;
@property (nonatomic, strong) NSNumber *hasMore;
@property (nonatomic, copy) NSArray<ACCVideoMusicCategoryModel *> *childrenCollections;
@property (nonatomic, copy) NSArray <NSDictionary *> *mcList;

@end
