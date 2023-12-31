//
//  BDUGTokenSharePreviewDialog.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/14.
//

#import "BDUGTokenSharePreviewDialog.h"
#import "BDUGTokenShareDialogManager.h"
#import "BDUGShareBaseUtil.h"
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import "UIColor+UGExtension.h"
#import "BDUGTokenShareBundle.h"
#import "BDUGTokenShareAnalysisResultTextDialogService.h"
#import "BDUGTokenShareAnalysisResultTextAndImageDialogService.h"
#import "BDUGTokenShareAnalysisResultVideoDialogService.h"

#pragma mark - content view

@interface BDUGTokenSharePreviewDialog ()

@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *tokenLabel;
@property(nonatomic, strong) UILabel *tipsLabel;
@property(nonatomic, strong) UIImageView *reportIconView;

@end

@implementation BDUGTokenSharePreviewDialog

#define kBDUGTokenShareDialogTokenFontSize 14
#define kBDUGTokenShareDialogTokenLineHeight 17

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithHexString:@"ffffff"];
        [self addSubview:self.titleLabel];
        [self addSubview:self.tokenLabel];
        [self addSubview:self.tipsLabel];
        [self addSubview:self.reportIconView];
    }
    return self;
}

- (void)refreshContent:(BDUGTokenShareInfo *)contentModel {
    self.titleLabel.text = contentModel.tokenTitle;
    self.tokenLabel.attributedText = [BDUGShareBaseUtil attributedStringWithString:contentModel.tokenDesc fontSize:self.tokenLabel.font.pointSize lineHeight:kBDUGTokenShareDialogTokenLineHeight lineBreakMode:NSLineBreakByTruncatingTail];
    self.tipsLabel.text = contentModel.tokenTips;
    self.reportIconView.hidden = isEmptyString(contentModel.tokenTips);
    [self refreshFrame];
}

- (void)refreshFrame {
    self.titleLabel.frame = CGRectMake(14 + (25 - self.titleLabel.font.pointSize)/2, 0, self.frame.size.width - 2 * 14, 25);
    
    self.tokenLabel.frame = CGRectMake(CGRectGetMinX(self.titleLabel.frame),CGRectGetMaxY(self.titleLabel.frame) + 5, self.titleLabel.frame.size.width, 0);
    self.tokenLabel.btd_height = [BDUGShareBaseUtil heightOfText:self.tokenLabel.text fontSize:kBDUGTokenShareDialogTokenFontSize forWidth:self.tokenLabel.frame.size.width forLineHeight:ceil(kBDUGTokenShareDialogTokenLineHeight) constraintToMaxNumberOfLines:self.tokenLabel.numberOfLines];
    
    self.tipsLabel.frame = CGRectMake(CGRectGetMinX(self.titleLabel.frame) + self.reportIconView.frame.size.width + 4, self.btd_height - 10 - 14, self.titleLabel.frame.size.width, 14);
    self.reportIconView.btd_centerY = self.tipsLabel.btd_centerY;
    self.reportIconView.btd_left = CGRectGetMinX(self.titleLabel.frame);
}

#pragma mark - setter && getter

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont boldSystemFontOfSize:19];
        _titleLabel.textColor = [UIColor colorWithHexString:@"222222"];
    }
    return _titleLabel;
}

- (UILabel *)tokenLabel {
    if (_tokenLabel == nil) {
        _tokenLabel = [UILabel new];
        _tokenLabel.numberOfLines = 4;
        _tokenLabel.font = [UIFont systemFontOfSize:kBDUGTokenShareDialogTokenFontSize];
        _tokenLabel.textColor = [UIColor colorWithHexString:@"222222"];
    }
    return _tokenLabel;
}

- (UILabel *)tipsLabel {
    if (_tipsLabel == nil) {
        _tipsLabel = [UILabel new];
        _tipsLabel.font = [UIFont systemFontOfSize:12];
        _tipsLabel.textColor = [UIColor colorWithHexString:@"999999"];
    }
    return _tipsLabel;
}

- (UIImageView *)reportIconView {
    if (_reportIconView == nil) {
        _reportIconView = [UIImageView new];
        _reportIconView.image = [UIImage imageNamed:@"tokenshare_dialog_report" inBundle:[BDUGTokenShareBundle resourceBundle] compatibleWithTraitCollection:nil];
        _reportIconView.frame = CGRectMake(0, 0, 12, 12);
    }
    return _reportIconView;
}

@end
