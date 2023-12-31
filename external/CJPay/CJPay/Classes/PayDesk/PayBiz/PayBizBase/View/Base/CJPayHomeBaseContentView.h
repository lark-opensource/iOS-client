//
//  CJPayHomeBaseContentView.h
//  CJPay
//
//  Created by 尚怀军 on 2020/3/24.
//

#import <UIKit/UIKit.h>
#import "CJPayBytePayMethodView.h"
#import "CJPayCounterLabel.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"

@protocol CJPayHomeContentViewDelegate<NSObject>

- (void)confirmButtonClick;

@end

NS_ASSUME_NONNULL_BEGIN

@class CJPayCreateOrderResponse;
@interface CJPayHomeBaseContentView : UIView <CJPayBaseLoadingProtocol>

@property (nonatomic, strong) CJPayCounterLabel *payAmountLabel;
@property (nonatomic, strong) UILabel *unitLabel;
@property (nonatomic, strong) UILabel *payAmountDiscountLabel;
@property (nonatomic, strong) UILabel *tradeNameLabel;
@property (nonatomic, strong) CJPayStyleButton *confirmPayBtn;
@property (nonatomic, strong) CJPayCreateOrderResponse *response;
@property (nonatomic, weak) id<CJPayMethodTableViewDelegate> tableViewDelegate;
@property (nonatomic, weak) id<CJPayHomeContentViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame
          createOrderResponse:(CJPayCreateOrderResponse *)createOrderResponse;

-(void)setupUI;

-(void)refreshDataWithModels:(NSArray *)models;

- (void)updateAmount:(NSInteger)toAmount from:(NSInteger)fromAmount;

@end

NS_ASSUME_NONNULL_END
