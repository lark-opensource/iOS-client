//
//  CJPayMethodQRCodePayCell.h
//  Pods
//
//  Created by 易培淮 on 2020/10/13.
//

#import "CJPayMethodTableViewWithArrowCell.h"

NS_ASSUME_NONNULL_BEGIN

@class MASConstraint;
@interface CJPayMethodQRCodePayCell : CJPayMethodTableViewWithArrowCell <CJPayMethodDataUpdateProtocol>


@property (nonatomic, strong, readonly) UIImageView *bankIconView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subTitleLabel;

@property (nonatomic, strong) MASConstraint *titleLabelTopBaseContentViewConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelBottomBaseContentViewConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelLeftBaseIconImageViewConstraint;

- (void)setupUI;
- (void)updateContent:(CJPayChannelBizModel *)model;

@end

NS_ASSUME_NONNULL_END
