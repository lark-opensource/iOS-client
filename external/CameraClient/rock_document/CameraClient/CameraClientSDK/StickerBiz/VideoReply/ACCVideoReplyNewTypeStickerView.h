//  视频回复视频贴纸样式优化
//  ACCVideoReplyNewTypeStickerView.h
//  CameraClient-Pods-Aweme
//  prd: https://bytedance.feishu.cn/docs/doccncjUirltfOnzA33MtLpEpBb
//  Created by lixuan on 2021/11/15.
//

#import <UIKit/UIKit.h>
#import <CameraClientModel/ACCVideoReplyModel.h>

#import "ACCStickerEditContentProtocol.h"
#import "ACCVideoReplyStickerViewProtocol.h"
#import "ACCStickerContentDisplayProtocol.h"


@interface ACCVideoReplyNewTypeStickerView : UIView <
ACCStickerEditContentProtocol,
ACCStickerContentDisplayProtocol,
ACCVideoReplyStickerViewProtocol
>

@property (nonatomic, strong, readonly, nullable) ACCVideoReplyModel *videoReplyModel;

- (nullable instancetype)initWithModel:(nullable ACCVideoReplyModel *)mode NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder NS_UNAVAILABLE;
- (nonnull instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)init NS_UNAVAILABLE;

@end

