//
//  ACCDuetAmountView.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/26.
//
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import "ACCDuetAmountView.h"
#import <Masonry/View+MASAdditions.h>

@interface ACCDuetAmountView ()

@property (nonatomic, strong) UILabel *amountLabel;

@end

@implementation ACCDuetAmountView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.amountLabel];
        ACCMasMaker(self.amountLabel, {
            make.edges.equalTo(self);
        });
        
        self.layer.cornerRadius = 2.0f;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [self.amountLabel intrinsicContentSize];
    return CGSizeMake(size.width, size.height);
}

- (UILabel *)amountLabel
{
    if (!_amountLabel) {
        _amountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _amountLabel.font = [ACCFont() acc_systemFontOfSize:12 weight:ACCFontWeightMedium];
        _amountLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
    }
    return _amountLabel;
}

- (void)setText:(NSString *)text
{
    self.amountLabel.text = text;
    [self invalidateIntrinsicContentSize];
}

- (void)invalidateIntrinsicContentSize
{
    [super invalidateIntrinsicContentSize];
    [self.amountLabel invalidateIntrinsicContentSize];
}


+ (NSString *)usageAmountString:(NSInteger)amount
{
    if (amount > pow(10, 8)) {
        return [NSString stringWithFormat:@"%.1f 亿次合拍", amount / pow(10, 8)];
    }
    
    if (amount > pow(10, 4)) {
        return [NSString stringWithFormat:@"%.1f 万次合拍", amount / pow(10, 4)];
    }
    return [NSString stringWithFormat:@"%ld 次合拍", (long)amount];
}


@end
