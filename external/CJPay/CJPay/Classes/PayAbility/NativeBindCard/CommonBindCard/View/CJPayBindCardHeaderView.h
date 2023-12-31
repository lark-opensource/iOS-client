//
//  CJPayBindCardHeaderView.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/11.
//

#import <UIKit/UIKit.h>
#import "CJPayBankCardAddRequest.h"
#import "CJPayBindCardNumberView.h"
#import "CJPayBindCardFirstStepBaseInputView.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayButton;

@interface BDPayBindCardHeaderViewDataModel : CJPayBindCardPageBaseModel

@property (nonatomic, copy) NSString *firstStepMainTitle;

@end

@interface CJPayBindCardHeaderView : UIView

@property (nonatomic, strong, readonly) CJPayButton *searchCardNoBtn;

// supportListButton
@property (nonatomic, copy) void(^didSupportListButtonClickBlock)(void);
@property (nonatomic, copy) void(^didClickSearchCardNoBlock)(void);

+ (NSArray <NSString *>*)dataModelKey;
- (instancetype)initWithBindCardDictonary:(NSDictionary *)dict isFirstStep:(BOOL)isFirstStep;
- (void)updateHeaderView:(BDPayBindCardHeaderViewDataModel *)dataModel;

@end

NS_ASSUME_NONNULL_END
