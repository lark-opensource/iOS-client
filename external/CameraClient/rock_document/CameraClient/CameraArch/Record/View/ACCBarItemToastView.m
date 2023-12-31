//
//  ACCBarItemToastView.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/8.
//

#import "ACCBarItemToastView.h"
#import <CreationKitInfra/ACCResponder.h>
#import "ACCDummyHitTestView.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <Masonry/View+MASAdditions.h>

static CGFloat kToastViewHeight = 34.f;

@interface ACCBarItemToastView ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) ACCDummyHitTestView *hitTestView;
@property (nonatomic, weak) UIView *anchorView;
@property (nonatomic, copy) dispatch_block_t dismissBlock;
@property (nonatomic, assign) BOOL dismissed;

@end

@implementation ACCBarItemToastView

static CGFloat accBarItemWidth = 0;

+ (void)showOnAnchorBarItem:(UIView *)barItem withContent:(NSString *)content dismissBlock:(nullable dispatch_block_t)dismissBlock
{
    ACCBarItemToastView *toast = [[ACCBarItemToastView alloc] init];
    toast.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT);
    toast.contentLabel.text = content;
    toast.anchorView = barItem;
    toast.dismissBlock = dismissBlock;
    toast.dismissed = NO;
    
    [toast p_showToastWithAniamtion];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.userInteractionEnabled = NO; 
        [self addSubview:self.backgroundView];
        [self.backgroundView addSubview:self.contentLabel];
        
        ACCMasMaker(self.contentLabel, {
            make.left.equalTo(self.backgroundView).offset(12);
            make.top.equalTo(self.backgroundView).offset(10);
            make.bottom.equalTo(self.backgroundColor).offset(-10);
        });
    }
    return self;
}

#pragma mark - Privates

- (void)p_showToastWithAniamtion
{
    UIView *interactionView = self.anchorView;
    UIView *belowView = interactionView;

    if (self.anchorView == nil) {
        AWELogToolInfo(AWELogToolTagRecord, @"ACCRecorderMeteorModeComponent showToast : input anchor view is nil");
    }

    while (interactionView != nil && interactionView.superview != [ACCResponder topView]) {
        belowView = interactionView;
        interactionView = interactionView.superview;
        if (interactionView == nil) {
            AWELogToolInfo(AWELogToolTagRecord, @"ACCRecorderMeteorModeComponent showToast : interactionView setted nil in while loop");
        }
    }

    [interactionView insertSubview:self belowSubview:belowView];

    CGRect anchorFrameOnTopView = [self.anchorView convertRect:self.anchorView.bounds toView:[ACCResponder topView]];
    
    ACCMasMaker(self.backgroundView, {
        make.top.equalTo(@(anchorFrameOnTopView.origin.y - (kToastViewHeight - anchorFrameOnTopView.size.height) / 2));
        make.width.equalTo(@(0));
        make.height.equalTo(@(kToastViewHeight));
        make.right.equalTo(self.superview).offset(-6);
    });
    
    self.backgroundView.alpha = 0;
    self.contentLabel.alpha = 0;
    
    [self.superview layoutIfNeeded];
    
    ACCMasUpdate(self.backgroundView, {
        make.width.equalTo(@([self p_contentWidth:self.contentLabel.text] + 53));
    });
    
    if ([self.anchorView isKindOfClass:UIButton.class]) {
        UIButton *itemButton = (UIButton *)self.anchorView;
        if (!accBarItemWidth) {
            accBarItemWidth = itemButton.imageView.frame.size.width;
        }
        ACCMasMaker(itemButton.imageView, {
            make.size.equalTo(@(CGSizeMake(accBarItemWidth * 0.875, accBarItemWidth * 0.875)));
        });
    }

    [UIView animateWithDuration:0.3 animations:^{
        [self.superview layoutIfNeeded];
        self.backgroundView.alpha = 1.0;
    } completion:nil];
     
    [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.contentLabel.alpha = 1.0;
    } completion:^(BOOL finished) {
        if (!finished) {
            ACCBLOCK_INVOKE(self.dismissBlock);
        }
        [self performSelector:@selector(p_dismissToastWithAnimation) withObject:nil afterDelay:3.0];
    }];
    
    [[ACCResponder topView] addSubview:self.hitTestView];
}

- (void)p_dismissToastWithAnimation
{
    if (!self.superview) {
        return;
    }
    
    ACCMasUpdate(self.backgroundView, {
        make.width.equalTo(@0);
    });
    
    if ([self.anchorView isKindOfClass:UIButton.class]) {
        UIButton *itemButton = (UIButton *)self.anchorView;
        ACCMasUpdate(itemButton.imageView, {
            make.size.equalTo(@(CGSizeMake(accBarItemWidth, accBarItemWidth)));
        });
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.superview layoutIfNeeded];
        self.backgroundView.alpha = 0;
    }];
 
    [UIView animateWithDuration:0.1 animations:^{
        self.contentLabel.alpha = 0;
    } completion:^(BOOL finished) {
        if (self.dismissed) {
            ACCBLOCK_INVOKE(self.dismissBlock);
        }
        self.dismissed = YES;
    }];

    
    [self performSelector:@selector(p_removeFromSuperView) withObject:nil afterDelay:0.3];
}

- (void)p_removeFromSuperView
{
    [self.hitTestView removeFromSuperview];
    [self removeFromSuperview];
}

- (CGFloat)p_contentWidth:(NSString *)content
{
    return [content boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                 options:NSStringDrawingUsesLineFragmentOrigin
                              attributes:@{NSFontAttributeName : [ACCFont() systemFontOfSize:13]}
                                 context:nil].size.width;
}

#pragma mark - Getters

- (UIView *)backgroundView
{
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = ACCResourceColor(ACCColorTextReverse3);
        _backgroundView.layer.cornerRadius = kToastViewHeight / 2.f;
        _backgroundView.layer.masksToBounds = YES;
    }
    return _backgroundView;
}

- (UILabel *)contentLabel
{
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [ACCFont() systemFontOfSize:13];
        _contentLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
    }
    return _contentLabel;
}

- (ACCDummyHitTestView *)hitTestView
{
    if (!_hitTestView) {
        _hitTestView = [[ACCDummyHitTestView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        @weakify(self);
        _hitTestView.hitTestHandler = ^{
            @strongify(self);
            [self p_dismissToastWithAnimation];
        };
    }
    return _hitTestView;
}

@end
