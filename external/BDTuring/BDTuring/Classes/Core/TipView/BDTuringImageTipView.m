//
//  BDTuringImageTipView.m
//  BDTuring
//
//  Created by bob on 2019/8/30.
//

#import "BDTuringImageTipView.h"
#import "BDTuringUtility.h"
#import "UIColor+TuringHex.h"
#import "BDTuringConfig.h"

@interface BDTuringImageTipView ()

@end

@implementation BDTuringImageTipView

- (instancetype)initWithFrame:(CGRect)frame language:(NSString *)language {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat width = frame.size.width;
        UIImage *image = [UIImage imageNamed:@"turing_NoNetwork" inBundle:turing_sdkBundle() compatibleWithTraitCollection:nil];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(width/2 - 50, 0, 100, 70)];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:imageView];

        UIView *view = [[UIView alloc] initWithFrame:imageView.bounds];
        view.backgroundColor = [UIColor turing_colorWithRGB:0xff5500 alpha:0.3];
        [imageView addSubview:view];

        UILabel *tipLable = [[UILabel alloc] initWithFrame:CGRectMake(0, 77, width, 20)];
        tipLable.font = [UIFont systemFontOfSize:15];
        tipLable.textAlignment = NSTextAlignmentCenter;
        [tipLable setTextColor:[UIColor turing_colorWithRGB:0x999999 alpha:1.0]];
        tipLable.text = turing_LocalizedString(@"not_found", language);
        [self addSubview:tipLable];
    }
    
    return self;
}

@end
