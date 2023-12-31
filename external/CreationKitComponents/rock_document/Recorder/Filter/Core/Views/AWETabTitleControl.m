//
//  AWETabTitleControl.m
//  AWEStudio
//
//Created by Li Yansong on July 27, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWETabTitleControl.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWETabTitleControl ()

@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong) UIView *yellowDotView;
@property (nonatomic, strong) UIView *indicatorView;

@end

@implementation AWETabTitleControl

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selectedFont = [ACCFont() acc_systemFontOfSize:17 weight:ACCFontWeightMedium];
        _unselectedFont = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
        [self setupUI];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self.titleLabel setFont:selected ? self.selectedFont: self.unselectedFont];
    [self.titleLabel setTextColor:ACCResourceColor(selected ? ACCUIColorConstTextInverse2 : ACCUIColorConstTextInverse3)];
//    self.indicatorView.hidden = !selected;
}

#pragma mark - Public

- (void)showYellowDot:(BOOL)show {
    self.yellowDotView.hidden = !show;
}

- (void)setIndicatorWidth:(CGFloat)indicatorWidth {
    if (indicatorWidth > 0 && _indicatorWidth != indicatorWidth) {
        [self.indicatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.centerX.equalTo(self.contentView);
            make.height.equalTo(@2);
            make.width.equalTo(@(indicatorWidth));
        }];
    }
    _indicatorWidth = indicatorWidth;
}

#pragma mark - Private

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = ACCResourceFont(ACCFontPrimary);
        [_titleLabel setTextColor:ACCResourceColor(ACCUIColorConstTextInverse2)];
    }
    return _titleLabel;
}

- (UIView *)yellowDotView {
    if (!_yellowDotView) {
        _yellowDotView = [[UIView alloc] init];
        _yellowDotView.layer.cornerRadius = 3;
        _yellowDotView.backgroundColor = ACCResourceColor(ACCColorLink);
        _yellowDotView.hidden = YES;
    }
    return _yellowDotView;
}

- (UIView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIView alloc] init];
        _indicatorView.backgroundColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _indicatorView.hidden = YES;
    }
    return _indicatorView;
}

- (void)setupUI {
    [self.contentView addSubview:self.titleLabel];
    ACCMasMaker(self.titleLabel, {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.contentView).offset(0);
    });
    
    [self.contentView addSubview:self.yellowDotView];
    ACCMasMaker(self.yellowDotView, {
        make.left.equalTo(self.titleLabel.mas_right).offset(2);
        make.top.equalTo(self.titleLabel.mas_top);
        make.height.width.equalTo(@6);
    });
     
    [self.contentView addSubview:self.indicatorView];
    ACCMasMaker(self.indicatorView, {
        make.bottom.centerX.equalTo(self.contentView);
        make.height.equalTo(@2);
        make.width.equalTo(self.titleLabel);
    });
}

+ (CGSize)collectionView:(UICollectionView *)collectionView sizeForTabTitleControlWithTitle:(NSString *)title font:(UIFont *)font
{
    if (title.length > 0) {
        CGSize textSize = [title boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT)
                                              options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                           attributes:@{NSFontAttributeName: font}
                                              context:nil].size;
        return CGSizeMake(textSize.width + 30, collectionView.bounds.size.height);
    }
    
    return CGSizeMake(1, collectionView.bounds.size.height);;
}

@end
