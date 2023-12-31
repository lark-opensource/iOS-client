//
//  ACCRecognitionGrootStickerView.m
//  CameraClient-Pods-Aweme
//
//  Created by Ryan Yan on 2021/8/23.
//

#import "ACCRecognitionGrootStickerView.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCRecognitionGrootStickerView ()

@property (nonatomic, strong) UIView *originSuperView;
@property (nonatomic, assign) CGPoint editCenter;

@end

@implementation ACCRecognitionGrootStickerView

@synthesize stickerContainer = _stickerContainer;
@synthesize coordinateDidChange = _coordinateDidChange;
@synthesize transparent = _transparent;
@synthesize stickerId = _stickerId;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.alpha = 0.75f;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickSelfView)];
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)configWithModel:(ACCGrootDetailsStickerModel *)grootStickerModel
{

}

- (void)transportToEditWithSuperView:(UIView *)superView
                           animation:(void (^)(void))animationBlock
                   animationDuration:(CGFloat)duration
{
    CGPoint center = [self.superview convertPoint:self.center toView:superView];
    CGAffineTransform transform = self.superview.transform; // Unreasonably design, refactor in the future
    [self removeFromSuperview];
    [superView addSubview:self];
    self.center = center;
    self.transform = transform;

    [UIView animateWithDuration:duration animations:^{
        self.transform = CGAffineTransformIdentity;
        ACCBLOCK_INVOKE(self.coordinateDidChange);
        [self updateEdtingFrames];
        if (animationBlock) {
            animationBlock();
        }
    } completion:^(BOOL finished) {

    }];
}

- (void)restoreToSuperView:(UIView *)superView
         animationDuration:(CGFloat)duration
            animationBlock:(void (^)(void))animationBlock
                completion:(void (^)(void))completion
{
    CGPoint center = [self.superview convertPoint:self.center toView:superView];
    CGAffineTransform transform = superView.transform;
    transform = CGAffineTransformInvert(transform);
    [self removeFromSuperview];
    [superView addSubview:self];
    self.center = center;
    self.transform = transform;

    [UIView animateWithDuration:duration animations:^{
        self.transform = CGAffineTransformIdentity;
        [self contentDidUpdateToScale:self.currentScale];
        ACCBLOCK_INVOKE(self.coordinateDidChange);
        if (animationBlock) {
            animationBlock();
        }
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (void)updateEdtingFrames
{
    CGPoint editCenter = CGPointMake(ACC_SCREEN_WIDTH * 0.5, ACC_SCREEN_HEIGHT * 0.27 - 26);
    if (@available(iOS 9.0, *)) {
        editCenter = [[[UIApplication sharedApplication].delegate window] convertPoint:editCenter toView:[self.stickerContainer containerView]];
    }
    self.center = CGPointMake(ACC_SCREEN_WIDTH / 2.f, editCenter.y - 52);

    _editCenter = self.center;
}

- (void)clickSelfView
{
    if ([self.delegate respondsToSelector:@selector(hitView:)]) {
        [self.delegate hitView:self];
    }
}

- (UIFont *)getSocialFont:(CGFloat)fontSize retry:(NSInteger)retry
{
    UIFont *font = nil;
    for (NSInteger i = 0; i < retry && !font; i++) {
        font = [ACCInteractionStickerFontHelper
                interactionFontWithFontName:ACCInteractionStcikerSocialFontName
                fontSize:fontSize];
    }
    return font ?: [UIFont boldSystemFontOfSize:fontSize];
}

@end
