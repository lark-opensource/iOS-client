//
//  ACCSocialStickerEditView.h
//  CameraClient-Pods-Aweme-CameraResource_base
//
//  Created by qiuhang on 2020/8/5.
//
//  edit view for social (mention/hashtag) stickerView

#import <UIKit/UIKit.h>
#import "ACCSocialStickerView.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCSocialStickerEditView : UIView

@property (nonatomic, strong, readonly) ACCSocialStickerView *editingStickerView;

ACCSocialStickerViewUsingCustomerInitOnly;
+ (instancetype)editViewWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

- (void)startEditStickerView:(ACCSocialStickerView *)textView;

@property (nonatomic, copy) void (^onEditFinishedBlock)(ACCSocialStickerView *stickerView);
@property (nonatomic, copy) void (^finishEditAnimationBlock)(ACCSocialStickerView *stickerView);
@property (nonatomic, copy) void (^startEditBlock)(ACCSocialStickerView *stickerView);

@end

NS_ASSUME_NONNULL_END
