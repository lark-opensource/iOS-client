//
//  CJPayStateView.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/26.
//

#import <Foundation/Foundation.h>
#import "CJPayImageLabelStateView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayStateType) {
    CJPayStateTypeSuccess,
    CJPayStateTypeFailure,
    CJPayStateTypeTimeOut,
    CJPayStateTypeWaiting,
    CJPayStateTypeNetException,
    CJPayStateTypeNone, // 隐藏
};

@protocol CJPayStateDelegate

- (void)stateButtonClick:(NSString *)buttonName;

@end

@interface CJPayStateView : UIView

@property (nonatomic, weak) id<CJPayStateDelegate> delegate;
@property (nonatomic, copy) NSString *pageDesc;
@property (nonatomic, copy) NSString *buttonDesc;
@property (nonatomic, assign) BOOL isPaymentForOuterApp;

- (void)updateShowConfigsWithType:(CJPayStateType)type model:(CJPayStateShowModel *)model;
- (void)startState:(CJPayStateType)state;
+ (NSMutableAttributedString *)updateTitleWithContent:(NSString *)text desc:(NSString *)desc;
+ (NSMutableAttributedString *)updateTitleWithContent:(NSString *)text amount:(NSString *)amount;
+ (NSMutableAttributedString *)updateTitleWithContent:(NSString *)text; //没有金额展示

@end

NS_ASSUME_NONNULL_END
