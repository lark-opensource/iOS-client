//
//  ACCButton.m
//  ACCme
//
//  Created by willorfang on 16/9/6.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCButton.h"
#import <Masonry/View+MASAdditions.h>

@implementation ACCButton

+ (instancetype)buttonWithSelectedAlpha:(CGFloat)selectedAlpha
{
    ACCButton *button = [self buttonWithType:UIButtonTypeCustom];
    button.selectedAlpha = selectedAlpha;

    return button;
}

+ (instancetype)imageButtonWithSelectedAlpha:(CGFloat)selectedAlpha
{
    ACCButton *button = [self buttonWithSelectedAlpha:selectedAlpha];
    
    button.imageContentView = [UIImageView new];
    [button addSubview:button.imageContentView];
    ACCMasMaker(button.imageContentView, {
        make.edges.equalTo(button);
    });
    
    return button;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if(self.highlighted) {
        [UIView animateWithDuration:0.15 animations:^{
            [self setAlpha:self.selectedAlpha];
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.15 animations:^{
                [self setAlpha:1];
            }];
        });
    }
}

@end
