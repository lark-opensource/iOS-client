//
//  CJPayMethodTableViewCell.h
//  CJPay
//
//  Created by wangxiaohong on 2020/5/18.
//

#import <Foundation/Foundation.h>

#import "CJPayChannelBizModel.h"
#import "CJPayMehtodDataUpdateProtocol.h"
#import "CJPayStyleCheckMark.h"
#import "CJPayDefaultChannelShowConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayPaddingLabel;
@class MASConstraint;
@class CJPayMethodCellTagView;
@interface CJPayMethodTableViewCell : UITableViewCell<CJPayMethodDataUpdateProtocol>

@property (nonatomic, strong, readonly) UIImageView *bankIconView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subTitleLabel;
@property (nonatomic, strong, readonly) CJPayStyleCheckMark *confirmImageView;
@property (nonatomic, strong, readonly) UIView *seperateView;
@property (nonatomic, strong, readonly) CJPayMethodCellTagView *suggestView;

@property (nonatomic, strong) MASConstraint *titleLabelTopBaseContentViewConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelBottomBaseContentViewConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelLeftBaseIconImageViewConstraint;
@property (nonatomic, strong, nullable) MASConstraint *titleLabelCenterBaseContentViewConstraint;

- (void)setupUI;
- (void)updateContent:(CJPayChannelBizModel *)model;

NS_ASSUME_NONNULL_END

@end

