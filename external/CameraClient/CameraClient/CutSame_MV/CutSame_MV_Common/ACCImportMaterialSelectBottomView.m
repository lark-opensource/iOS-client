//
//  ACCImportMaterialSelectBottomView.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/13.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCImportMaterialSelectBottomView.h"
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCImportMaterialSelectBottomView ()

@property (nonatomic, strong) UIView *seperatorLineView;

@end

@implementation ACCImportMaterialSelectBottomView
@synthesize titleLabel = _titleLabel;
@synthesize nextButton = _nextButton;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _seperatorLineView = [[UIView alloc] init];
        _seperatorLineView.backgroundColor = ACCResourceColor(ACCColorLineReverse2);
        [self addSubview:_seperatorLineView];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightMedium];
        _titleLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.numberOfLines = 1;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_titleLabel];
        
        _nextButton = [[UIButton alloc] init];
        [_nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_nextButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateDisabled];
        [_nextButton setTitle:@"next" forState:UIControlStateNormal];
        _nextButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        _nextButton.titleEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
        _nextButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-12, -12, -12, -12);
        _nextButton.layer.cornerRadius = 2.0f;
        _nextButton.clipsToBounds = YES;
        [self addSubview:_nextButton];
        
        ACCMasMaker(_seperatorLineView, {
            make.leading.trailing.top.equalTo(@(0.0f));
            make.height.equalTo(@(0.5f));
        });
        
        ACCMasMaker(_titleLabel, {
            make.leading.equalTo(@(16.0f));
            make.top.equalTo(@(0));
            make.height.equalTo(@(52.0f));
            make.trailing.equalTo(_nextButton.mas_leading).offset(-16.0f);
        });
        
        CGSize sizeFits = [_nextButton sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
        ACCMasMaker(_nextButton, {
            make.top.equalTo(@(8.0f));
            make.height.equalTo(@(36.0f));
            make.trailing.equalTo(@(-16.0f));
            make.width.equalTo(@(sizeFits.width+24));
        });
        
        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_nextButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        // Disable the next button by default.
        _nextButton.enabled = NO;
        _nextButton.backgroundColor = ACCResourceColor(ACCColorBGInputReverse);
    }
    return self;
}

@end
