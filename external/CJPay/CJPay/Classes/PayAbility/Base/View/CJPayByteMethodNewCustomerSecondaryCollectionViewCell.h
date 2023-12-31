//
//  CJPayByteMethodNewCustomerSecondaryCollectionViewCell.h
//  CJPaySandBox
//
//  Created by 郑秋雨 on 2022/12/22.
//

#import <UIKit/UIKit.h>
@class CJPaySubPayTypeInfoModel;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayByteMethodNewCustomerSecondaryCollectionViewBankSelectedCell : UICollectionViewCell

- (void)loadData:(CJPaySubPayTypeInfoModel *)data;

@end

@interface CJPayByteMethodNewCustomerSecondaryCollectionViewMoreCell : UICollectionViewCell

@end

NS_ASSUME_NONNULL_END
