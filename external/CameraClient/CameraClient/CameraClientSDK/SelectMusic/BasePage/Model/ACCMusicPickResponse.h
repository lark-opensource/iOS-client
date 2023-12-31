//
//  ACCMusicPickResponse.h
//  CameraClient
//
//  Created by 李彦松 on 2018/9/4.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#import <CreationKitArch/ACCMusicModelProtocol.h>
#import "ACCMusicTransModelProtocol.h"
#import <CreationKitInfra/ACCBaseApiModel.h>

@class ACCVideoMusicCategoryModel;

@interface ACCMusicPickResponse : ACCBaseApiModel

@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSArray<id<ACCBannerModelProtocol>> *banners;
@property (nonatomic, copy) NSArray<ACCVideoMusicCategoryModel *> *categories;
@property (nonatomic, strong) NSArray<id<ACCMusicModelProtocol>> *musicList;
@property (nonatomic, strong) NSArray<id<ACCMusicModelProtocol>> *extraMusicList;
@property (nonatomic, assign) NSInteger musicListType; // 0 推荐歌单， 1 电台
@property (nonatomic, strong) NSNumber *FMCursor;
@property (nonatomic, assign) BOOL hasMore;

@end
