//
//  BDPBadgeLabel.m
//  Timor
//
//  Created by tujinqiu on 2020/2/2.
//

#import "BDPBadgeLabel.h"
#import <OPFoundation/UIColor+BDPExtension.h>

static CGFloat const kBDPBadgeHeight = 19;
static CGFloat const kBDPBadgeGap = 4.5;
static CGFloat const kBDPBadgeBorderWidth = 1.5;

@implementation BDPBadgeLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.textColor = [UIColor whiteColor];
        self.font = [UIFont systemFontOfSize:12];
        self.textAlignment = NSTextAlignmentCenter;
        self.layer.cornerRadius = kBDPBadgeHeight / 2.0;
        self.layer.borderColor = UIColor.whiteColor.CGColor;
        self.layer.borderWidth = kBDPBadgeBorderWidth;
        self.layer.masksToBounds = YES;
        self.backgroundColor = [UIColor colorWithHexString:@"#F54A45"];
        self.hidden = YES;
    }

    return self;
}

- (void)setBadge:(NSString *)badge
{
    self.text = badge;
}

- (void)setNum:(NSUInteger)num
{
    if (num <= 0) {
        self.hidden = YES;
        return;
    }
    self.hidden = NO;
    NSString *badge = @(num).stringValue;
    if (self.maxNum > 0 && num > self.maxNum) {
        badge = @"∙∙∙";
    }
    [self setBadge:badge];
}

- (CGSize)suitableSize
{
    CGSize size = [self sizeThatFits:CGSizeMake(kBDPBadgeHeight, kBDPBadgeHeight)];
    size.width = size.width + kBDPBadgeGap * 2.0;
    if (size.width < kBDPBadgeHeight) {
        size.width = kBDPBadgeHeight;
    }
    size.height = kBDPBadgeHeight;

    return size;
}

@end
