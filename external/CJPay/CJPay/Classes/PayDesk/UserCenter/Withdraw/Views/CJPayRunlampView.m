//
//  CJPayRunlampView.m
//  CJPay
//
//  Created by 王新华 on 10/12/19.
//

#import "CJPayRunlampView.h"
#import "CJPayUIMacro.h"

@interface CJPayRunlampView()
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UIView *marqueeView;
@property (nonatomic, strong) UIView *containerView;

@end

@implementation CJPayRunlampView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _contentMargin = 16;
        self.clipsToBounds = YES;
        _containerView = [UIView new];
        [self addSubview:_containerView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.containerView cj_removeAllSubViews];
    CGSize marqueeSize = [self.marqueeView sizeThatFits:self.cj_size];
    self.marqueeView.frame = CGRectMake(0, 0, marqueeSize.width, marqueeSize.height);
    [self.containerView addSubview:self.marqueeView];
    if (marqueeSize.width > self.cj_width) {
        UIView *copyMarquee = [self.marqueeView cj_copy];
        [self.containerView addSubview:copyMarquee];
        copyMarquee.frame = CGRectMake(marqueeSize.width + self.contentMargin, 0, marqueeSize.width, marqueeSize.height);
        self.containerView.frame = CGRectMake(0, 0, marqueeSize.width * 2 + self.contentMargin * 2, marqueeSize.height);
    } else {
        self.containerView.frame = self.bounds;
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (!newSuperview) {
        [self stopMarquee];
    }
}

- (void)startMarqueeWith:(UIView *)view {
    self.marqueeView = view;
    CGSize marqueeSize = [view sizeThatFits:self.cj_size];
    if (marqueeSize.width <= self.cj_width) {
        [self stopMarquee];
    } else {
        [self startMarquee];
    }
    [self setNeedsLayout];
}

- (void)startMarquee {
    [self stopMarquee];
    self.displayLink = [CADisplayLink displayLinkWithTarget:[BTDWeakProxy proxyWithTarget:self] selector:@selector(processMarquee)];
    if (@available(iOS 10.0, *)) {
        self.displayLink.preferredFramesPerSecond = 30;
    } else {
        self.displayLink.frameInterval = 2;
    }
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopMarquee {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)processMarquee {
    CGSize marqueeSize = [self.marqueeView sizeThatFits:self.cj_size];
    CGFloat singleWidth = marqueeSize.width + self.contentMargin;
    CGRect curFrame = self.containerView.frame;
    if (ABS(curFrame.origin.x) > singleWidth) {
        curFrame.origin.x = curFrame.origin.x + singleWidth - self.pointsPerFrame;
    } else {
        curFrame.origin.x = curFrame.origin.x - self.pointsPerFrame;
    }
    self.containerView.frame = curFrame;
}

@end
