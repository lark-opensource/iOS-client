//
//  BDTuringNetworkTipView.m
//  BDTuring
//
//  Created by bob on 2019/8/28.
//

#import "BDTuringNetworkTipView.h"
#import "BDTuringConfig.h"
#import "BDTuringVerifyView.h"
#import "BDTuringUtility.h"
#import "UIColor+TuringHex.h"

@interface BDTuringNetworkTipView ()

@end

@implementation BDTuringNetworkTipView

- (instancetype)initWithFrame:(CGRect)frame language:(NSString *)language target:(BDTuringVerifyView *)target {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        CGFloat width = frame.size.width;
        CGFloat height = frame.size.height;
        UIColor *titleColor = [UIColor turing_colorWithRGB:0x222222 alpha:1.0];

        UILabel *titleLable = [[UILabel alloc] initWithFrame:CGRectMake(12, 16, width - 12, 24)];
        titleLable.font = [UIFont systemFontOfSize:17];
        titleLable.textAlignment = NSTextAlignmentLeft;
        titleLable.textColor = titleColor;
        titleLable.text = turing_LocalizedString(@"verify", language);
        [self addSubview:titleLable];


        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(width - 28, 8, 20, 20)];
        UIImage *image = [UIImage imageNamed:@"turing_close" inBundle:turing_sdkBundle() compatibleWithTraitCollection:nil];
        [closeButton setImage:image forState:(UIControlStateNormal)];
        [closeButton addTarget:target action:@selector(closeVerifyViewFromFeedbackClose) forControlEvents:(UIControlEventTouchUpInside)];
        [self addSubview:closeButton];

        UILabel *tipLable = [[UILabel alloc] initWithFrame:CGRectMake(12, height / 2 - 30, width - 24, 20)];
        tipLable.font = [UIFont systemFontOfSize:14];
        tipLable.textAlignment = NSTextAlignmentCenter;
        [tipLable setTextColor:[UIColor turing_colorWithRGB:0x999999 alpha:1.0]];
        tipLable.text = turing_LocalizedString(@"service_error", language);
        [self addSubview:tipLable];

        UIButton *feedbackButton = [[UIButton alloc] initWithFrame:CGRectMake(width/2 - 45, height/2 + 5, 90, 25)];
        feedbackButton.backgroundColor = [UIColor turing_colorWithRGB:0xe8e8e8 alpha:1.0];
        feedbackButton.layer.cornerRadius = 4;
        feedbackButton.layer.masksToBounds = YES;
        feedbackButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [feedbackButton setTitleColor:titleColor forState:UIControlStateNormal];
        NSString *text = turing_LocalizedString(@"feed_back", language);
        [feedbackButton setTitle:text forState:(UIControlStateNormal)];
        [feedbackButton addTarget:target action:@selector(closeVerifyViewFromFeedbackButton) forControlEvents:(UIControlEventTouchUpInside)];
        [self addSubview:feedbackButton];

        self.userInteractionEnabled = YES;
        /// block tap to superview
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeIgnored)];
        [self addGestureRecognizer:tap];
    }

    return self;
}

- (void)closeIgnored {

}

@end
