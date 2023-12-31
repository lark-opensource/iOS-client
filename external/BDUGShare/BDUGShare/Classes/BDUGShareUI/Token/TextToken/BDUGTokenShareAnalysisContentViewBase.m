//
//  BDUGTokenShareAnalysisContentViewBase.m
//  Article
//
//  Created by zengzhihui on 2018/6/1.
//

#import "BDUGTokenShareAnalysisContentViewBase.h"
#import "BDUGTokenShareAnalysisResultCommom.h"
#import <BDUGShare/BDUGTokenShareModel.h>
#import "UIColor+UGExtension.h"
#import "BDUGTokenShareBundle.h"
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import "BDUGShareBaseUtil.h"

@implementation BDUGTokenShareAnalysisContentViewBase

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _titleLineHeight = 25;
        [self addSubview:self.titleLabel];
        [self addSubview:self.tipsLabel];
        self.backgroundColor = [UIColor colorWithHexString:@"ffffff"];
    }
    return self;
}

- (void)refreshContent:(BDUGTokenShareAnalysisResultModel *)resultModel {
    _insideModel = resultModel;
    self.titleLabel.attributedText = [BDUGShareBaseUtil attributedStringWithString:resultModel.title fontSize:self.titleLabel.font.pointSize lineHeight:_titleLineHeight lineBreakMode:NSLineBreakByTruncatingTail];
    if (!isEmptyString(resultModel.shareUserName)) {
        NSString *tip = [NSString stringWithFormat:@"此分享来自%@，查看 TA",resultModel.shareUserName];
        NSMutableAttributedString *attributeText = [[NSMutableAttributedString alloc] initWithString:tip];
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        attach.image = [UIImage imageNamed:@"tokenshare_more" inBundle:BDUGTokenShareBundle.resourceBundle compatibleWithTraitCollection:nil];
        attach.bounds = CGRectMake(0, 0, attach.image.size.width, attach.image.size.height);
        NSAttributedString *attachString = [NSAttributedString attributedStringWithAttachment:attach];
        [attributeText appendAttributedString:attachString];
        self.tipsLabel.attributedText = attributeText;
        self.tipsLabel.hidden = NO;
    } else {
        self.tipsLabel.hidden = YES;
    }
    [self refreshFrame];
}

- (void)refreshFrame {
    CGFloat leftOffset = 15;
    self.tipsLabel.frame = CGRectMake(leftOffset, self.btd_height - 32, self.btd_width - 30, 16);
}

- (void)tapUserAction {
    if (self.tipTapBlock) {
        self.tipTapBlock();
    }
}

#pragma mark - setter && getter

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont systemFontOfSize:19];
        _titleLabel.textColor = [UIColor colorWithHexString:@"222222"];
    }
    return _titleLabel;
}

- (UILabel *)tipsLabel {
    if (_tipsLabel == nil) {
        _tipsLabel = [UILabel new];
        _tipsLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _tipsLabel.font = [UIFont systemFontOfSize:14];
        _tipsLabel.textColor = [UIColor colorWithHexString:@"999999"];
        _tipsLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapUserAction)];
        [_tipsLabel addGestureRecognizer:tap];
    }
    return _tipsLabel;
}
@end
