//
//  CJPayByteMethodNewCustomerSecondaryCell.h
//  CJPaySandBox
//
//  Created by 郑秋雨 on 2022/12/21.
//

#import <UIKit/UIKit.h>

@protocol CJPayMethodTableViewDelegate;
@class CJPayBytePayMethodView;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayByteMethodNewCustomerSecondaryCell : UITableViewCell

@property (nonatomic, weak) id<CJPayMethodTableViewDelegate> _Nullable subPayDelegate;

@end

NS_ASSUME_NONNULL_END
