//
//  ACCVideoReplyStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  视频评论视频
//
//  Created by Daniel on 2021/7/27.
//

#import <Foundation/Foundation.h>

#import "ACCStickerHandler.h"
#import "ACCShootSameStickerHandlerProtocol.h"

@class ACCVideoReplyModel;

#ifndef ACCVideoReplyStickerHandlerDelegation_h
#define ACCVideoReplyStickerHandlerDelegation_h
@protocol ACCVideoReplyStickerHandlerDelegation <NSObject>

- (void)willDeleteVideoReplyStickerView;

@optional
- (nullable NSString *)generateVideoReplyDraftPath:(NSUInteger)index;
- (void)willCreateStickerView:(nullable ACCVideoReplyModel *)videoReplyModel;
- (nullable NSString *)getTrackEnterMethod;

@end
#endif

@interface ACCVideoReplyStickerHandler : ACCStickerHandler <ACCStickerMigrationProtocol>

@property (nonatomic, weak, nullable) id<ACCVideoReplyStickerHandlerDelegation> delegation;

/// createStickerView
/// @param videoReplyModel
/// @param locationModel if locationModel is nil, the sticker will be placed on the top-left position
- (nonnull UIView<ACCStickerProtocol> *)createStickerView:(nullable ACCVideoReplyModel *)videoReplyModel
                                            locationModel:(nullable AWEInteractionStickerLocationModel *)locationModel;

- (void)removeVideoReplyStickerView;

@end

