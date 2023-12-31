//
//  ACCPollStickerView.h
//  CameraClient-Pods-DouYin
//
//  Created by guochenxiang on 2020/9/7.
//

#import <UIKit/UIKit.h>
#import "ACCStickerEditContentProtocol.h"
#import "ACCPollStickerViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEPollStickerView, ACCPollStickerView, AWEInteractionStickerModel;

@interface ACCPollStickerView : UIView <ACCStickerEditContentProtocol, ACCPollStickerViewProtocol>

@property (nonatomic, strong) AWEInteractionStickerModel *model;
@property (nonatomic, copy) NSString *effectIdentifier;

@property (nonatomic, strong) AWEPollStickerView *stickerView;

@property (nonatomic, assign) CGPoint basicCenter;
@property (nonatomic, assign) CGPoint lastCenter;//在编辑页的center(非写文字时的center)
@property (nonatomic, assign) CGFloat leftBeyond;
@property (nonatomic, assign) CGFloat keyboardHeight;

@property (nonatomic, assign) BOOL isDraftRecover;//草稿箱恢复并且没有编辑过

- (void)updateWithModel:(AWEInteractionStickerModel *)model;

- (void)resetWithSuperView:(UIView *)superView;

- (void)transToRecordPosWithSuperView:(UIView *)superView
                           completion:(void (^)(void))completion;

- (void)updateEditTypeWithTap:(UITapGestureRecognizer *)gesture;

@end

NS_ASSUME_NONNULL_END
