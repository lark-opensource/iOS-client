//
//  AWEPollStickerView.h
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by chengfei xiao on 2019/4/26.
//

#import <UIKit/UIKit.h>
#import "ACCPollStickerOptionView.h"
#import <UITextView+Placeholder/UITextView+Placeholder.h>

#define kAWEPollStickerWitdth                 210.f
#define kAWEPollStickerQuestionDefaultHeight  40.f
#define kAWEPollStickerMaxLines               3

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AWEPollStickerEditType) {
    AWEPollStickerEditTypeNone = 0,
    AWEPollStickerEditTypeQuestion,  //question
    AWEPollStickerEditTypeOPT1,      //option1
    AWEPollStickerEditTypeOPT2,      //option2
};

@interface AWEPollStickerView : UIView
@property (nonatomic, strong) UITextView *questionView;
@property (nonatomic, strong) UIView *option1BGView;
@property (nonatomic, strong) UIView *option2BGView;
@property (nonatomic, strong) UITextView *option1View;
@property (nonatomic, strong) UITextView *option2View;
@property (nonatomic, strong) ACCPollStickerOptionView *option1DisplayView;
@property (nonatomic, strong) ACCPollStickerOptionView *option2DisplayView;
@property (nonatomic, assign) AWEPollStickerEditType currentEditType;
@property (nonatomic, strong) CALayer *op1ShadowLayer;
@property (nonatomic, strong) CALayer *op2ShadowLayer;

@property (nonatomic, copy) void (^finishEditBlock) (void);

//设置字体时更新默认文案宽度
- (void)refreshPlaceHolderWidth;

//有问题文字，开始、完成编辑、输入文字，更新约束
- (void)updateQuestionConstraints;

//没有输入问题，完成编辑的时候不保留问题位置
- (void)updateQuestionConstraintsWhenHide:(BOOL)hide;

//没有输入问题，完成编辑的时候不显示问题的placeholder
- (void)displayQuestionPlaceHolder:(BOOL)show;

//为了解决layer和view移动速度不一致的问题, calayer 没有约束动画
- (void)displayShadowLayer:(BOOL)show;

//更新选项的约束
- (void)updateOptionsConstraints;

//开启预览模式
- (void)showDisplayMode:(BOOL)open;

@end

NS_ASSUME_NONNULL_END
