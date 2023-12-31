//  视频回复评论二期链路优化
//  ACCVideoReplyCommentWithoutCoverStickerView.h
//  CameraClient-Pods-Aweme
//
//  Created by lixuan on 2021/10/8.
//

#import <UIKit/UIKit.h>
#import <CameraClientModel/ACCVideoReplyCommentModel.h>

#import "ACCStickerEditContentProtocol.h"
#import "ACCVideoReplyStickerViewProtocol.h"
#import "ACCStickerContentDisplayProtocol.h"


@interface ACCVideoReplyCommentWithoutCoverStickerView : UIView
<
ACCStickerEditContentProtocol,
ACCStickerContentDisplayProtocol,
ACCVideoReplyStickerViewProtocol
>

@property (nonatomic, strong, readonly, nullable) ACCVideoReplyCommentModel *videoReplyCommentModel;

- (nullable instancetype)initWithModel:(nullable ACCVideoReplyCommentModel *)model;
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder NS_UNAVAILABLE;
- (nonnull instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)init NS_UNAVAILABLE;

+ (CGSize)frameSizeWithModel:(nullable ACCVideoReplyCommentModel *)model;

@end

