//
//  ACCModernPinStickerPlayer.m
//  CameraClient
//
//  Created by Pinka.
//

#import "ACCModernPinStickerPlayer.h"
#import <CreationKitInfra/UIView+ACCRTL.h>

@interface ACCModernPinStickerPlayer ()

@property (nonatomic, strong) UIView *selectedStickerView;
@property (nonatomic, copy  ) NSString *currentStickerIds;
@property (nonatomic, copy  ) NSDictionary *initialStickerInfoDict;
@property (nonatomic, copy  ) NSDictionary *initialStickerSizeDict;

@end

@implementation ACCModernPinStickerPlayer

#pragma mark - public methods

- (void)configWhenContainerDidAppear
{
    
}

- (void)configWhenContainerWillDisappear
{
    
}

- (void)setPlayerContainerFrame:(CGRect)frame content:(UIView *)content
{
    NSAssert(content, @"should not be nil");
    if (!self.contentView.superview && content) {
        [content addSubview:self.contentView];
    }
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.contentView.frame = frame;
}

#pragma mark - Getter & Setter
- (UIView *)contentView
{
    return self.playerContainer;
}

- (UIView *)playerContainer
{
    if (!_playerContainer) {
        _playerContainer = [UIView new];
        _playerContainer.layer.cornerRadius = 2;
        _playerContainer.layer.masksToBounds = YES;
        _playerContainer.accrtl_viewType = ACCRTLViewTypeNormal;
    }

    return _playerContainer;
}

- (void)setInteractionImageView:(UIImageView *)interactionImageView
{
    [_interactionImageView removeFromSuperview];
    _interactionImageView = interactionImageView;
    interactionImageView.alpha = 0.5;
    [self.contentView addSubview:_interactionImageView];
    _interactionImageView.frame = self.contentView.bounds;
    _interactionImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
}

@end
