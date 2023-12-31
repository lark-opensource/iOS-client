//
//  CJWithdrawResultProgressCell.m
//  CJPay
//
//  Created by liyu on 2019/10/12.
//

#import "CJPayWithDrawResultProgressCell.h"
#import "CJPayUIMacro.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayWithDrawResultProgressItem.h"
#import "UIView+CJTheme.h"

@interface CJPayWithDrawResultProgressCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIView *upperSegment;
@property (nonatomic, strong) UIView *lowerSegment;
@property (nonatomic, strong) CJPayWithDrawResultProgressItem *processItem;

@property (nonatomic, strong) MASConstraint *titleBottomConstraint;
@property (nonatomic, strong) MASConstraint *lowerSegmentConstraint;

@end

@implementation CJPayWithDrawResultProgressCell

+ (CGFloat)cellHeight {
    return 88;
}

+ (NSString *)identifier {
    NSString *result = [CJPayWithDrawResultProgressCell description];
    if (result.length == 0) {
        result = @"CJWithdrawResultProgressCell";
    }
    return result;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self p_setupUI];
    }
    return self;
}

- (void)p_updateBottomConstraint
{
    if (self.timeLabel.hidden) {
        [self.lowerSegmentConstraint deactivate];
        [self.titleBottomConstraint activate];
    } else {
        [self.titleBottomConstraint deactivate];
        [self.lowerSegmentConstraint activate];
    }
}

- (void)p_adapterThemeWithItem:(CJPayWithDrawResultProgressItem *)item {
    CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
    self.upperSegment.backgroundColor = localTheme.withdrawSegmentBackgroundColor;
    self.lowerSegment.backgroundColor = localTheme.withdrawSegmentBackgroundColor;
    switch (item.state) {
        case kCJWithdrawResultProgressItemStateSuccess:
        case kCJWithdrawResultProgressItemStateProcessing: {
            [self.iconImageView cj_setImage:@"cj_withdraw_success_icon"];
            self.titleLabel.textColor = localTheme.withdrawTitleTextColor;
            self.timeLabel.textColor = localTheme.withdrawSubTitleTextColor;
            self.timeLabel.hidden = NO;
        }
            break;
            
        case kCJWithdrawResultProgressItemStateUpcoming: {
            [self.iconImageView cj_setImage: item.isLast ? localTheme.withdrawResultIconImageThreeName : localTheme.withdrawResultIconImageTwoName];
            self.titleLabel.textColor = localTheme.withdrawUpcomingTextColor;
            self.timeLabel.hidden = YES;
        }
            break;
            
        case kCJWithdrawResultProgressItemStateFail: {
            [self.iconImageView cj_setImage:@"cj_withdraw_fail_icon"];
            self.titleLabel.textColor = localTheme.withdrawTitleTextColor;
            self.timeLabel.textColor = localTheme.withdrawSubTitleTextColor;
            self.timeLabel.hidden = NO;
        }
            break;
    }
    
    [self p_updateBottomConstraint];
}

#pragma mark - Views

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
    }
    return _titleLabel;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabel.font = [UIFont cj_fontOfSize:14];
    }
    return _timeLabel;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
    }
    return _iconImageView;
}

- (UIView *)upperSegment {
    if (!_upperSegment) {
        _upperSegment = [[UIView alloc] init];
        _upperSegment.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _upperSegment;
}

- (UIView *)lowerSegment {
    if (!_lowerSegment) {
        _lowerSegment = [[UIView alloc] init];
        _lowerSegment.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _lowerSegment;
}

#pragma mark - Private

- (void)p_setupUI {
    self.contentView.backgroundColor = [UIColor clearColor];
    self.backgroundColor = [UIColor clearColor];
    
    [self.contentView addSubview:self.iconImageView];
    
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.timeLabel];

    [self.contentView addSubview:self.upperSegment];
    [self.contentView addSubview:self.lowerSegment];

    CJPayMasMaker(self.iconImageView, {
        make.left.equalTo(self.contentView).offset(16);
        make.width.height.mas_equalTo(20);
        make.centerY.equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.centerY.equalTo(self.iconImageView);
        make.left.equalTo(self.iconImageView.mas_right).offset(12);
        make.right.lessThanOrEqualTo(self.contentView);
        self.titleBottomConstraint = make.bottom.equalTo(self.contentView.mas_bottom).offset(-24);
    });
    [self.titleBottomConstraint deactivate];
    
    CJPayMasMaker(self.timeLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self.titleLabel);
        make.height.mas_equalTo(CJ_SIZE_FONT_SAFE(12));
    });
    
    CJPayMasMaker(self.upperSegment, {
        make.centerX.equalTo(self.iconImageView);
        make.width.mas_equalTo(2);
        make.top.equalTo(self.contentView);
        make.bottom.equalTo(self.iconImageView.mas_top);
        make.height.mas_equalTo(34);
    });
    
    CJPayMasMaker(self.lowerSegment, {
        make.centerX.equalTo(self.iconImageView);
        make.width.mas_equalTo(2);
        make.height.equalTo(self.upperSegment);
        make.top.equalTo(self.iconImageView.mas_bottom);
        self.lowerSegmentConstraint = make.bottom.equalTo(self.contentView);
    });
}

- (void)updateWithItem:(CJPayWithDrawResultProgressItem *)item {
    self.upperSegment.hidden = item.isFirst;
    self.lowerSegment.hidden = item.isLast;
    
    self.titleLabel.text = item.titleText;
    self.timeLabel.text = item.timeText;

    self.processItem = item;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        [self p_adapterThemeWithItem:self.processItem];
    }
}

@end
