//
//  CJPayBytePayMethodCell.h
//  Pods
//
//  Created by wangxiaohong on 2021/4/13.
//

#import "CJPayMethodTableViewCell.h"
#import "CJPayLoadingManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayMethodCellTagView;

@interface CJPayBytePayMethodCell : CJPayMethodTableViewCell<CJPayBaseLoadingProtocol>

@property (nonatomic, strong, readonly) UILabel *rightMsgLabel;
@property (nonatomic, strong, readonly) CJPayMethodCellTagView *discountView;
@property (nonatomic, strong, readonly) UIImageView *rightArrowImage;

@end

NS_ASSUME_NONNULL_END
