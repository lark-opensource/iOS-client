//
//  ACCRecognitionEditGrootStickerView.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/31.
//

#import "ACCRecognitionEditGrootStickerView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/AWEEditGradientView.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface ACCRecognitionEditGrootStickerView()

@property (nonatomic, strong) ACCRecognitionGrootStickerView *grootStickerView;
@property (nonatomic, strong) AWEEditGradientView *upperMaskView;
@property (nonatomic, strong) UIView *lowerMaskView;
@property (nonatomic,   weak) UIView *orignalSuperView;
@property (nonatomic, assign) BOOL isEdting;

@end

@implementation ACCRecognitionEditGrootStickerView

@synthesize grootStickerView = _grootStickerView;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT);
        [self setup];
    }
    return self;
}

- (void)setup {
    self.lowerMaskView = ({
        UIView *view = [[UIView alloc] init];
        [self addSubview:view];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        [view acc_addSingleTapRecognizerWithTarget:self action:@selector(didClickedTextMaskView)];
        ACCMasMaker(view, {
            make.edges.equalTo(self);
        });
        view.alpha = 0.f;
        view;
    });

    self.upperMaskView = ({
        AWEEditGradientView *view = [[AWEEditGradientView alloc] init];
        [self addSubview:view];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [UIColor clearColor];
        view.clipsToBounds = YES;
        ACCMasMaker(view, {
            make.top.equalTo(self.mas_top).offset(52.f + ACC_NAVIGATION_BAR_OFFSET);
            make.right.left.bottom.equalTo(self);
        });
        view.alpha = 0.f;
        view;
    });
}

#pragma mark - public

- (void)startEditStickerView:(ACCRecognitionGrootStickerView *_Nonnull)stickerView
{
    if (self.isEdting) {
        return;
    }
    self.isEdting = YES;
    self.orignalSuperView = stickerView.superview;
    self.grootStickerView = stickerView;

    ACCBLOCK_INVOKE(self.startEditBlock, stickerView);

    self.upperMaskView.alpha = 1;
    @weakify(self);
    [self.grootStickerView transportToEditWithSuperView:self.upperMaskView animation:^{
        @strongify(self);
        self.lowerMaskView.alpha = 1;
        self.grootStickerView.alpha = 1;
    } animationDuration:0.26];
}

- (void)stopEdit {
    if (!self.isEdting) {
        return;
    }
    self.isEdting = NO;
    @weakify(self);
    [self.grootStickerView restoreToSuperView:self.orignalSuperView
                            animationDuration:0.26
                            animationBlock:^{
        @strongify(self)
        self.lowerMaskView.alpha = 0;
        self.grootStickerView.alpha = 0.75;
    } completion:^{
        @strongify(self);
        ACCBLOCK_INVOKE(self.onEditFinishedBlock, self.grootStickerView);
        self.upperMaskView.alpha = 0;
        self.grootStickerView = nil;
    }];
}

#pragma mark - action
- (void)didClickedTextMaskView {
    [self stopEdit];
}

@end
