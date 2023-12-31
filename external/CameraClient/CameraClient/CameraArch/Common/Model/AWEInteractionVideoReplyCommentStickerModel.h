//  视频回复评论二期
//  AWEInteractionVideoReplyCommentStickerModel.h
//  CameraClientModel-Pods-Aweme
//
//  Created by lixuan on 2021/10/8.
//

#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <CameraClientModel/ACCVideoReplyCommentModel.h>

@interface AWEInteractionVideoReplyCommentStickerModel : AWEInteractionStickerModel

@property (nonatomic, strong, nullable) ACCVideoReplyCommentModel *videoReplyCommentInfo;

@end
