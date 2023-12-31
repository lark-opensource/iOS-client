//
//  CJPayPayAgainCreditPayView.h
//  Pods
//
//  Created by liutianyi on 2022/2/26.
//

#import <UIKit/UIKit.h>

#import "CJPayBytePayMethodCreditPayCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPayAgainCreditPayView : UIView

@property (nonatomic, strong, readonly) UIImageView *bankIconImageView;
@property (nonatomic, strong, readonly) UILabel *bankLabel;
@property (nonatomic, strong, readonly) CJPayBytePayMethodCreditPayCollectionView *collectionView;

@end

NS_ASSUME_NONNULL_END
