//
//  ACCVideoCommentStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/18.
//

#import <Foundation/Foundation.h>

#import "ACCStickerHandler.h"
#import "ACCShootSameStickerHandlerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCVideoCommentStickerHandler : ACCStickerHandler <ACCStickerMigrationProtocol, ACCShootSameStickerHandlerProtocol>

@end

NS_ASSUME_NONNULL_END
