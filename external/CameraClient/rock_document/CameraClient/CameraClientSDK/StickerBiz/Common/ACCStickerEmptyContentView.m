//
//  ACCStickerEmptyContentView.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/3/9.
//

#import "ACCStickerEmptyContentView.h"

@implementation ACCStickerEmptyContentView

@synthesize coordinateDidChange;
@synthesize stickerId;
@synthesize transparent = _transparent;;
@synthesize stickerContainer;

- (instancetype)initWithStickerModel:(AWEInteractionStickerModel *)model
{
    self = [super init];
    if (self) {
        _model = model;
    }
    self.userInteractionEnabled = NO;
    return self;
}

- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    self.alpha = transparent? 0.5: 1.0;
}

@end
