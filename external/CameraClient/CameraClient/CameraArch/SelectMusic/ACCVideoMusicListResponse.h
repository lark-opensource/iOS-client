//
//  ACCVideoMusicListResponse.h
//  CameraClient
//
//  Created by xiangwu on 2017/6/14.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <CreationKitInfra/ACCBaseApiModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import "ACCVideoMusicCategoryModel.h"


@interface ACCVideoMusicListResponse : ACCBaseApiModel

@property (nonatomic, strong) NSArray <NSDictionary *> *mcList;
@property (nonatomic, strong) NSNumber *cursor;
@property (nonatomic, strong) NSNumber *hasMore;
@property (nonatomic, strong) NSNumber *musicType;
@property (nonatomic, strong) ACCVideoMusicCategoryModel *titleModel;  //在通过站内信或者标签直接请求歌单时，需要从response里面去到title名称

- (NSArray<id<ACCMusicModelProtocol>> *)musicList;

@end
