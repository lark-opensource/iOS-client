//
//  ACCMusicPanelAnimator.m
//  CameraClient
//
//  Created by wishes on 2020/2/28.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCMusicPanelAnimator.h"
#import "ACCMusicPanelViewProtocol.h"
#import <CameraClient/ACCCameraClient.h>

@interface ACCMusicPanelAnimator()

@property (nonatomic, strong) UIView<ACCMusicPanelViewProtocol> * panel;

@end

@implementation ACCMusicPanelAnimator
@synthesize animationDidEnd;
@synthesize targetView;
@synthesize animationWillStart;
@synthesize type;
@synthesize containerView;


- (instancetype)initWithAnimationType:(ACCPanelAnimationType)type {
    if (self = [super init]) {
        self.type = type;
    }
    return self;
}

- (void)animate {
    [self configPanel];
    if (self.type == ACCPanelAnimationShow) {
        [self animateIn];
    } else {
        [self animateOut];
    }
}

- (void)configPanel {
    if ([self.targetView conformsToProtocol:@protocol(ACCMusicPanelViewProtocol)]) {
        self.panel = (UIView<ACCMusicPanelViewProtocol> *)self.targetView;
        @weakify(self);
        self.panel.dismissHandler = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.animationDidEnd,self);
        };
        self.panel.showHandler = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.animationDidEnd,self);
        };
    }
}

- (void)animateIn {
    [self.containerView addSubview:self.targetView];
    ACCMasMaker(self.targetView, {
      make.edges.equalTo(self.containerView);
    });
    ACCBLOCK_INVOKE(self.animationWillStart,self);
    [self.panel show];
}

- (void)animateOut {
    ACCBLOCK_INVOKE(self.animationWillStart,self);
    [self.panel dismiss];
}



@end
