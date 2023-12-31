//
//  ACCRecorderPendantView.m
//  Aweme
//
//  Created by HuangHongsen on 2021/11/2.
//

#import "ACCRecorderPendantView.h"
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <lottie-ios/Lottie/LOTAnimationDelegate.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImageView+ACCAddtions.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@class ACCRecorderPendantCloseButtonView;
@protocol ACCRecorderPendantCloseButtonViewDelegate <NSObject>

- (void)touchBeginInCloseButton:(ACCRecorderPendantCloseButtonView *)closeButton;
- (void)touchMovedInCloseButton:(ACCRecorderPendantCloseButtonView *)closeButton withinTouchArea:(BOOL)withinTouchArea;
- (void)touchEndInCloseButton:(ACCRecorderPendantCloseButtonView *)closeButton shouldClose:(BOOL)shouldClose;
@end

@interface ACCRecorderPendantCloseButtonView : UIImageView
@property (nonatomic, weak) id<ACCRecorderPendantCloseButtonViewDelegate> delegate;
@end

@implementation ACCRecorderPendantCloseButtonView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self touchesWithinInteractionArea:touches]) {
        [self.delegate touchBeginInCloseButton:self];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    BOOL withinTouchArea = [self touchesWithinInteractionArea:touches];
    [self.delegate touchMovedInCloseButton:self withinTouchArea:withinTouchArea];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    BOOL withinTouchArea = [self touchesWithinInteractionArea:touches];
    [self.delegate touchEndInCloseButton:self shouldClose:withinTouchArea];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    BOOL withinTouchArea = [self touchesWithinInteractionArea:touches];
    [self.delegate touchEndInCloseButton:self shouldClose:withinTouchArea];
}

- (BOOL)touchesWithinInteractionArea:(NSSet<UITouch *> *)touches
{
    CGRect touchArea = CGRectInset(self.bounds, -10, -10);
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    if (CGRectContainsPoint(touchArea, location)) {
        return YES;
    } else {
        return NO;
    }
}

@end

@interface ACCRecorderPendantView ()<LOTAnimationDelegate, ACCRecorderPendantCloseButtonViewDelegate>
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) ACCRecorderPendantCloseButtonView *closeButtonView;
@end

static const CGFloat kACCRecorderPendantViewWidth = 90.f;

@implementation ACCRecorderPendantView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat closeButtonWidth = 16.f;
        CGFloat closeButtonPadding = 4.f;
        _closeButtonView = [[ACCRecorderPendantCloseButtonView alloc] initWithFrame:CGRectMake(kACCRecorderPendantViewWidth - closeButtonWidth - closeButtonPadding, closeButtonPadding, closeButtonWidth, closeButtonWidth)];
        _closeButtonView.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
        _closeButtonView.delegate = self;
        _closeButtonView.image = ACCResourceImage(@"icon_close_sticker");
        _closeButtonView.backgroundColor = [UIColor clearColor];
        _closeButtonView.userInteractionEnabled = YES;
        [self addSubview:_closeButtonView];
    }
    return self;
}

+ (CGSize)pendentSize
{
    return CGSizeMake(kACCRecorderPendantViewWidth, kACCRecorderPendantViewWidth);
}

- (void)loadResourceWithType:(ACCRecorderPendantResourceType)resourceType urlList:(NSArray *)iconURLList lottieJSON:(NSDictionary *)json completion:(void (^)(BOOL))completion
{
    if (self.resourceLoaded) {
        ACCBLOCK_INVOKE(completion, YES);
        return ;
    }
    if (self.contentView) {
        [self.contentView removeFromSuperview];
    }
    if (resourceType == ACCRecorderPendantResourceTypeLottie) {
        LOTAnimationView *lottieView = [[LOTAnimationView alloc] initWithFrame:CGRectMake(0, 0, kACCRecorderPendantViewWidth, kACCRecorderPendantViewWidth)];
        lottieView.userInteractionEnabled = YES;
        lottieView.contentMode = UIViewContentModeScaleAspectFit;
        lottieView.loopAnimation = YES;
        [lottieView setAnimationFromJSON:json];
        lottieView.animationDelegate = self;
        self.contentView = lottieView;
        UITapGestureRecognizer *tapOnContent = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnContent)];
        [self.contentView addGestureRecognizer:tapOnContent];
        [self addSubview:lottieView];
        [self bringSubviewToFront:self.closeButtonView];
        [lottieView play];
        self.resourceLoaded = YES;
        ACCBLOCK_INVOKE(completion, YES);
    } else if (resourceType == ACCRecorderPendantResourceTypePNG) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kACCRecorderPendantViewWidth, kACCRecorderPendantViewWidth)];
        imageView.userInteractionEnabled = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.contentView = imageView;
        UITapGestureRecognizer *tapOnContent = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnContent)];
        [self.contentView addGestureRecognizer:tapOnContent];
        [self addSubview:imageView];
        [self bringSubviewToFront:self.closeButtonView];
        @weakify(self);
        [ACCWebImage() imageView:imageView setImageWithURLArray:iconURLList placeholder:nil completion:^(UIImage * image, NSURL *url, NSError * error) {
            @strongify(self);
            if (image && !error) {
                ACCBLOCK_INVOKE(completion, YES);
                self.resourceLoaded = YES;
            } else {
                ACCBLOCK_INVOKE(completion, NO);
                self.resourceLoaded = NO;
            }
        }];
    } else {
        self.resourceLoaded = NO;
        self.contentView = nil;
        ACCBLOCK_INVOKE(completion, NO);
    }
}

#pragma mark - Event Handling

- (void)handleTapOnContent
{
    [self.delegate userDidTapOnPendantView:self];
}

#pragma mark - ACCRecorderPendantCloseButtonViewDelegate

- (void)touchEndInCloseButton:(ACCRecorderPendantCloseButtonView *)closeButton shouldClose:(BOOL)shouldClose
{
    [UIView animateWithDuration:0.15 animations:^{
        self.alpha = 1.f;
    }];
    if (shouldClose) {
        [self.delegate userDidClosePendantView:self];
    }
}

- (void)touchBeginInCloseButton:(ACCRecorderPendantCloseButtonView *)closeButton
{
    [UIView animateWithDuration:0.15 animations:^{
        self.alpha = 0.5;
    }];
}

- (void)touchMovedInCloseButton:(ACCRecorderPendantCloseButtonView *)closeButton withinTouchArea:(BOOL)withinTouchArea
{
    [UIView animateWithDuration:0.15 animations:^{
        self.alpha = withinTouchArea ? 0.5 : 1.f;
    }];
}

@end
