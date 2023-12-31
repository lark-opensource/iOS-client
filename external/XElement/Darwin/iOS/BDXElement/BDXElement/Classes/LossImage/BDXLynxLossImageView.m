//
//  BDXLynxLossImageView.m
//  BDXElement
//
//  Created by hanzheng on 2021/2/23.
//

#import "BDXLynxLossImageView.h"
#import "BDXLossImageView.h"
#import <Lynx/LynxComponentRegistry.h>

@interface BDXLynxLossImageView() <BDXLossImageViewDelegate>

@property(nonatomic, strong) BDXLossImageView *imageView;

- (void)requestImage;

@end

@implementation BDXLynxLossImageView

- (UIView *)createView {
    BDXLossImageView* image = [BDXLossImageView new];
    image.clipsToBounds = YES;
    // Default contentMode UIViewContentModeScaleToFill
    image.contentMode = UIViewContentModeScaleToFill;
    image.delegate = self;
    self.imageView = image;
    return image;
}

- (void)viewWillMoveToWindow:(UIWindow *)window {
    if (window == nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if ([self view].window == nil) {
                self.view.image = nil;
                [self setValue:nil forKey:@"image"];
            }
        });
    } else {
        if (self.view.image == nil) {
            [self requestImage];
        }
    }
}

LYNX_REGISTER_UI("loss-image")

@end
