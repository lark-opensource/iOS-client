//
//  ACCVideoMusicCategoryModel.h
//  CameraClient
//
//  Created by xiangwu on 2017/6/14.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <Mantle/Mantle.h>

#import <CreationKitArch/ACCURLModelProtocol.h>

@interface ACCVideoMusicCategoryModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *idStr;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) id<ACCURLModelProtocol> cover;
@property (nonatomic, strong) id<ACCURLModelProtocol> awemeCover;
@property (nonatomic, assign) BOOL isHot; // 是否是热门分类
@property (nonatomic, assign) NSInteger level;
@end
