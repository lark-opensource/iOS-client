//
//  ACCVideoReplyStickerView.h
//  CameraClient-Pods-Aweme
//
//  视频评论视频
//
//  Created by Daniel on 2021/7/27.
//

#import <UIKit/UIKit.h>
#import <CameraClientModel/ACCVideoReplyModel.h>

#import "ACCStickerEditContentProtocol.h"
#import "ACCVideoReplyStickerViewProtocol.h"
#import "ACCStickerContentDisplayProtocol.h"

@interface ACCVideoReplyStickerView : UIView <
ACCStickerEditContentProtocol,
ACCStickerContentDisplayProtocol,
ACCVideoReplyStickerViewProtocol
>

@property (nonatomic, strong, readonly, nullable) ACCVideoReplyModel *videoReplyModel;

- (nullable instancetype)initWithModel:(nullable ACCVideoReplyModel *)model;
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder NS_UNAVAILABLE;
- (nonnull instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)init NS_UNAVAILABLE;

@end
