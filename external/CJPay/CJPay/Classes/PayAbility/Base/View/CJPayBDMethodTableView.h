//
//  CJPayBDMethodTableView.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/18.
//

#import <UIKit/UIKit.h>

#import "CJPayLoadingManager.h"

@class CJPayChannelBizModel;
@protocol CJCJPayBDMethodTableViewDelegate <NSObject>

- (void)didSelectAtIndex:(int) selectIndex;

@end

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBDMethodTableView : UIView<CJPayBaseLoadingProtocol>

@property (nonatomic, copy) NSArray *models;
@property (nonatomic, weak) id<CJCJPayBDMethodTableViewDelegate> delegate;

- (void)startLoadingAnimationOnAddBankCardCell;
- (void)stopLoadingAnimationOnAddBankCardCell;

@end

NS_ASSUME_NONNULL_END
