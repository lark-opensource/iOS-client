//
//  ACCMvAmountView.m
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/7/6.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCMvAmountView.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCMvAmountView ()

@property (nonatomic, strong) UILabel *amountLabel;

@end

@implementation ACCMvAmountView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.amountLabel];
        ACCMasMaker(self.amountLabel, {
            make.top.equalTo(@3);
            make.bottom.equalTo(@-3);
            make.left.equalTo(@5);
            make.right.equalTo(@-5);
        });
        
        self.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
        self.layer.cornerRadius = 2;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [self.amountLabel intrinsicContentSize];
    return CGSizeMake(size.width + 10, size.height + 6);
}

- (UILabel *)amountLabel
{
    if (!_amountLabel) {
        _amountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _amountLabel.font = [ACCFont() acc_systemFontOfSize:11 weight:ACCFontWeightMedium];
        _amountLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
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


+ (NSString *)usageAmountString:(NSUInteger)amount
{
    if (amount > pow(10, 8)) {
        return [NSString stringWithFormat:ACCLocalizedCurrentString(@"creation_mv_user_count_more_than_100m"), amount / pow(10, 8)];
    }
    
    if (amount > pow(10, 4)) {
        return [NSString stringWithFormat:ACCLocalizedCurrentString(@"creation_mv_user_count_more_than_10k"), amount / pow(10, 4)];
    }
    return [NSString stringWithFormat:ACCLocalizedCurrentString(@"creation_mv_user_count_less_than_10k"), amount];
}

@end
