//
//  CJPayBytePayMethodCreditPayCollectionView.h
//  Pods
//
//  Created by bytedance on 2021/8/5.
//

#import <UIKit/UIKit.h>

@class CJPayBytePayCreditPayMethodModel;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBytePayMethodCreditPayCollectionView : UIView

@property (nonatomic, copy) NSArray<CJPayBytePayCreditPayMethodModel *> *creditPayMethods;
@property (nonatomic, copy) void(^clickBlock)(NSString *installment);
@property (nonatomic, assign) BOOL scrollAnimated;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
