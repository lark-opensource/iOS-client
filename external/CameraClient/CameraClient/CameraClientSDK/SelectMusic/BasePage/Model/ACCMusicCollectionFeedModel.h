//
//  ACCMusicCollectionFeedModel.h
//  CameraClient
//
//  Created by 李彦松 on 2018/9/4.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Mantle/Mantle.h>

#import <CreationKitArch/ACCMusicModelProtocol.h>
#import "ACCMusicTransModelProtocol.h"


@class ACCVideoMusicCategoryModel;
@interface ACCMusicCollectionFeedModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) ACCVideoMusicCategoryModel *category;
@property (nonatomic, strong) NSArray<id<ACCMusicModelProtocol>> *musicList;

@end
