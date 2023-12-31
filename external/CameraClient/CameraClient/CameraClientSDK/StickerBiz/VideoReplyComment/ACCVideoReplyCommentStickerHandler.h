//  视频回复评论二期
//  ACCVideoReplyCommentStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by lixuan on 2021/10/9.
//


#import "ACCStickerHandler.h"
#import "ACCVideoReplyStickerHandler.h"

@class ACCVideoReplyCommentModel;

@interface ACCVideoReplyCommentStickerHandler : ACCStickerHandler <ACCStickerMigrationProtocol>

@property (nonatomic, weak, nullable) id<ACCVideoReplyStickerHandlerDelegation> delegation;


/// createStickerView
/// @param videoReplyCommentModel
/// @param locationModel if locationModel is nil, the sticker will be placed on the top-left position
- (nonnull UIView<ACCStickerProtocol> *)addStickerViewWithModel:(nullable ACCVideoReplyCommentModel *)videoReplyCommentModel
                                            locationModel:(nullable AWEInteractionStickerLocationModel *)locationModel;

- (void)removeVideoReplyCommentStickerView;
@end
