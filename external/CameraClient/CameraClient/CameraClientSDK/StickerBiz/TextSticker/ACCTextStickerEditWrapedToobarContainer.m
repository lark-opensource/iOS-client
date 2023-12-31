//
//  ACCTextStickerEditWrapedToobarContainer.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/11.
//

#import "ACCTextStickerEditWrapedToobarContainer.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>

@implementation ACCTextStickerEditWrapedToobarContainer

- (instancetype)initWithFrame:(CGRect)frame normalToolBar:(UIView *)normalToolBar socialToolBar:(UIView *)socialToolBar
{
    if (self = [super initWithFrame:frame]) {
        _normalToolBar = normalToolBar;
        _socialToolBar = socialToolBar;
        [self p_setup];
        [self p_updateToolbarShow];
    }
    return self;
}

- (void)p_setup
{
    _currentToobarType = ACCTextStickerEditToolbarTypeNormal;
    
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = NO;
    
    if (self.normalToolBar) {
        [self addSubview:self.normalToolBar];
        self.normalToolBar.acc_bottom = self.acc_height;
    }
    if (self.socialToolBar) {
        [self addSubview:self.socialToolBar];
        self.socialToolBar.acc_bottom = self.acc_height;
    }
}

- (void)switchToToolbarType:(ACCTextStickerEditToolbarType)toolbarType
{
    if (toolbarType == _currentToobarType) {
        return;
    }
    
    _currentToobarType = toolbarType;
    [self p_updateToolbarShow];
}

- (void)p_updateToolbarShow
{
    if (self.currentToobarType == ACCTextStickerEditToolbarTypeNormal) {
        self.normalToolBar.hidden = NO;
        self.socialToolBar.hidden = YES;
    } else {
        self.normalToolBar.hidden = YES;
        self.socialToolBar.hidden = NO;
    }
}

@end
