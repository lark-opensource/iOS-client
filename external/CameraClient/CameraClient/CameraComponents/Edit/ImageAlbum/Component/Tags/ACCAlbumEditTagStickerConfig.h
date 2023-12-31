//
//  ACCAlbumEditTagStickerConfig.h
//  CameraClient-Pods-AwemeCore
//
//  Created by yangguocheng on 2021/9/29.
//

#import "ACCCommonStickerConfig.h"

@interface ACCAlbumEditTagStickerConfig : ACCCommonStickerConfig

@property (nonatomic, copy, nullable) void (^edit)(void);
@property (nonatomic, copy, nullable) void (^changeDirection)(void);

@end
