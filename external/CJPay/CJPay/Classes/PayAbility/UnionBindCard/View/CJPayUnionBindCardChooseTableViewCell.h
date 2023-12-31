//
//  CJPayUnionBindCardChooseTableViewCell.h
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayUnionCardInfoModel;
@interface CJPayUnionBindCardChooseTableViewCell : UITableViewCell

- (void)updateWithUnionCardInfoModel:(CJPayUnionCardInfoModel *)model;

@property (nonatomic, assign) BOOL isSelected;

@end

NS_ASSUME_NONNULL_END
