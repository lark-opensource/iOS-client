//
//  CJPayStyleImageView.m
//  CJPay-Example
//
//  Created by wangxinhua on 2020/9/23.
//

#import "CJPayStyleImageView.h"
#import "CJPayUIMacro.h"

@implementation CJPayStyleImageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_applyDefaultAppearance];
    }
    return self;
}

- (void)setStyleImage:(NSString *)imageName {
    [self setImage:imageName backgroundColor:nil];
}

- (void)setImage:(NSString *)imageName backgroundColor:(UIColor * _Nullable)color {
    @CJWeakify(self)
    [self cj_setImage:imageName completion:^(BOOL isSuccess) {
        @CJStrongify(self)
        if (isSuccess) {
            if (color) {
                self.backgroundColor = color;
            } else {
                CJPayStyleImageView *appearance = [CJPayStyleImageView appearance];
                if (appearance.backgroundColor == nil) {
                    self.backgroundColor = [UIColor cj_fe2c55ff];
                } else {
                    self.backgroundColor = [CJPayStyleImageView appearance].backgroundColor;
                }
            }
        } else {
            self.backgroundColor = [UIColor clearColor];
        }
    }];
}

- (void)p_applyDefaultAppearance {
    self.backgroundColor = [UIColor cj_skeletonScreenColor];
}

- (void)setImageWithURL:(NSURL *)imageURL {
    @CJWeakify(self)
    [self cj_setImageWithURL:imageURL placeholder:nil completion:^(UIImage * _Nonnull image, NSData * _Nonnull data, NSError * _Nonnull error) {
        @CJStrongify(self)
        if (!error) {
            CJPayStyleImageView *appearance = [CJPayStyleImageView appearance];
            if (appearance.backgroundColor) {
                self.backgroundColor = appearance.backgroundColor;
            }
        }
    }];
}

@end
