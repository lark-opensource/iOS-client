//
//  CJPayByteMethodNewCustomerSecondaryCollectionView.h
//  CJPaySandBox
//
//  Created by 郑秋雨 on 2022/12/21.
//

#import <UIKit/UIKit.h>

@protocol CJPayMethodTableViewDelegate;
@class CJPayChannelBizModel;
@class CJPayBytePayMethodView;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayByteMethodNewCustomerSecondaryCollectionView : UIView

@property (nonatomic, weak) id<CJPayMethodTableViewDelegate> _Nullable subPayDelegate;

- (void)reloadData:(CJPayChannelBizModel *)data;

@end

NS_ASSUME_NONNULL_END
