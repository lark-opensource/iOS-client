//
//  CJPayFrontMethodAddCardCell.m
//  Pods
//
//  Created by 尚怀军 on 2020/12/17.
//

#import "CJPayFrontMethodAddCardCell.h"

#import "CJPayChannelBizModel.h"

@implementation CJPayFrontMethodAddCardCell

- (void)setupUI {
    [super setupUI];
    self.seperateView.hidden = YES;
    
    self.titleLabel.font = [UIFont cj_boldFontOfSize:15];
    self.titleLabel.textColor = [UIColor cj_161823ff];
    
    self.titleLabelLeftBaseIconImageConstraint.offset = 12;
    CJPayMasUpdate(self.addIconImageView, {
        make.left.equalTo(self).offset(15);
    });
    
    CJPayMasUpdate(self.arrowImageView, {
        make.right.equalTo(self).offset(-21);
        make.width.height.mas_equalTo(20);
    });
    
    [self.addIconImageView cj_setImage:@"cj_addbankcard_icon"];
    [self.arrowImageView cj_setImage:@"cj_arrow_icon"];
}

- (void)updateContent:(CJPayChannelBizModel *)data {
    [super updateContent:data];
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data {
    return @(56);
}

@end
