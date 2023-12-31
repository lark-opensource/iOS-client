//
//  ACCPublishStrongPopView.m
//  CameraClient-Pods-Aweme
//
//  Created by ZZZ on 2021/2/23.
//

#import "ACCPublishStrongPopView.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIApplication+ACC.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCAnimatedButton.h>

@interface ACCPublishStrongPopContentView : UIView

@property (nonatomic, strong, readonly) UIView *backgroundView;
@property (nonatomic, strong, readonly) UIButton *closeButton;
@property (nonatomic, strong, readonly) ACCAnimatedButton *sureButton;

@end

@implementation ACCPublishStrongPopContentView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self p_init];
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect rect = self.backgroundView.bounds;
    CGSize radii = CGSizeMake(12, 12);
    UIRectCorner corners = UIRectCornerTopLeft | UIRectCornerTopRight;
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:radii].CGPath;
    self.backgroundView.layer.mask = layer;
}

- (void)p_init
{
    _backgroundView = ({
        UIView *view = [[UIView alloc] init];
        [self addSubview:view];
        view.backgroundColor = [UIColor whiteColor];

        ACCMasMaker(view, {
            make.left.right.top.bottom.equalTo(self);
        });

        view;
    });

    _closeButton = ({
        UIButton *view = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:view];
        UIImage *image = ACCResourceImage(@"edit_guide_diary_close");
        [view setImage:image forState:UIControlStateNormal];
        view.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);

        ACCMasMaker(view, {
            make.top.mas_equalTo(12);
            make.right.mas_equalTo(-12);
            make.size.mas_equalTo(image.size);
        })

        view;
    });

    UIView *arrowView = ({
        UIImage *image = ACCResourceImage(@"edit_guide_diary_arrow_big");
        UIImageView *view = [[UIImageView alloc] initWithImage:image];
        [self addSubview:view];

        ACCMasMaker(view, {
            make.top.equalTo(self).offset(48);
            make.size.mas_equalTo(image.size);
            make.centerX.equalTo(self);
        })

        view;
    });

    UILabel *titleLabel = ({
        UILabel *view = [[UILabel alloc] init];
        [self addSubview:view];
        view.textColor = ACCResourceColor(ACCColorTextReverse);
        view.font = [ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium];
        view.text = @"发布日常内容";

        ACCMasMaker(view, {
            make.top.equalTo(arrowView.mas_bottom).offset(16);
            make.height.mas_equalTo(24);
            make.centerX.equalTo(self);
        })

        view;
    });

    UILabel *detailLabel = ({
        UILabel *view = [[UILabel alloc] init];
        [self addSubview:view];
        view.textColor = ACCResourceColor(ACCColorTextReverse2);
        view.font = [ACCFont() systemFontOfSize:14];
        view.numberOfLines = 0;

        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.alignment = NSTextAlignmentCenter;
        style.maximumLineHeight = 22;
        style.minimumLineHeight = 22;
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        attributes[NSFontAttributeName] = view.font;
        attributes[NSForegroundColorAttributeName] = view.textColor;
        attributes[NSParagraphStyleAttributeName] = style;
        NSString *text = @"发布日常内容后，你的内容在 24 小时内可以被浏览，过期之后内容会自动设为私密作品。";
        view.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];

        ACCMasMaker(view, {
            make.top.equalTo(titleLabel.mas_bottom).offset(16);
            make.left.equalTo(self).offset(16);
            make.right.equalTo(self).offset(-16);
        });

        view;
    });

    _sureButton = ({
        ACCAnimatedButton *view = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [self addSubview:view];
        view.layer.cornerRadius = 2.0;
        view.backgroundColor = ACCResourceColor(ACCColorPrimary);
        view.titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
        [view setTitle:@"立即发布" forState:UIControlStateNormal];
        [view setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];

        ACCMasMaker(view, {
            make.top.equalTo(detailLabel.mas_bottom).offset(24);
            make.left.equalTo(self).offset(16);
            make.right.equalTo(self).offset(-16);
            make.height.mas_equalTo(44);
            UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
            if (@available(iOS 11.0, *)) {
                safeAreaInsets = [UIApplication acc_currentWindow].safeAreaInsets;
            }
            make.bottom.equalTo(self).offset(-safeAreaInsets.bottom - 8);
        });

        view;
    });
}

@end

@interface ACCPublishStrongPopView ()

@property (nonatomic, strong, readonly) UIView *backgroundView;
@property (nonatomic, strong, readonly) ACCPublishStrongPopContentView *contentView;
@property (nonatomic, copy) void (^publishBlock)(void);

@end

@implementation ACCPublishStrongPopView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView.alpha = 0;
    [self addSubview:_backgroundView];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [_backgroundView addGestureRecognizer:({
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBackgroundAction)];
    })];

    _contentView = [[ACCPublishStrongPopContentView alloc] init];
    [self addSubview:_contentView];
    ACCMasMaker(_contentView, {
        make.left.right.equalTo(self);
        make.top.equalTo(self.mas_bottom);
    });
    [_contentView.closeButton addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    [_contentView.sureButton addTarget:self action:@selector(sureAction) forControlEvents:UIControlEventTouchUpInside];

    return self;
}

- (void)tapBackgroundAction
{
    [self popup:NO animated:YES completion:nil];
}

- (void)closeAction
{
    [self popup:NO animated:YES completion:nil];
}

- (void)sureAction
{
    void (^completion)(void) = self.publishBlock;
    self.publishBlock = nil;
    [self popup:NO animated:YES completion:completion];
}

- (void)popup:(BOOL)popup animated:(BOOL)animated completion:(void (^)(void))completion
{
    ACCMasUpdate(self.contentView, {
        CGFloat offset = popup ? -self.contentView.bounds.size.height : 0;
        make.top.equalTo(self.mas_bottom).offset(offset);
    });

    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundView.alpha = popup ? 1 : 0;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (!popup) {
            [self removeFromSuperview];
        }
        ACCBLOCK_INVOKE(completion);
    }];
}

+ (void)showInView:(UIView *)view publishBlock:(void (^)(void))publishBlock
{
    ACCPublishStrongPopView *popView = [[ACCPublishStrongPopView alloc] initWithFrame:view.bounds];
    popView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:popView];
    popView.publishBlock = publishBlock;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [popView popup:YES animated:YES completion:nil];
    });
}

@end
