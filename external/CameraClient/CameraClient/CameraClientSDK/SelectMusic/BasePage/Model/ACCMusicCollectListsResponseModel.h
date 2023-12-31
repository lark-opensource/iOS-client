//
//  ACCMusicCollectListsResponseModel.h
//  CameraClient
//
//  Created by hanxu on 2017/3/20.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <CreationKitInfra/ACCBaseApiModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import "ACCMusicTransModelProtocol.h"

@interface ACCMusicCollectListsResponseModel : ACCBaseApiModel
@property (nonatomic, copy) NSArray<id<ACCMusicModelProtocol>> *mcList;
@property (nonatomic, strong) NSNumber *cursor;
@property (nonatomic, assign) BOOL hasMore;
@end
