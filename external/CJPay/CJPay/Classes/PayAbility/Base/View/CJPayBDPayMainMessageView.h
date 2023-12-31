//
//  CJPayBDPayMainMessageView.h
//  CJPay
//
//  Created by wangxiaohong on 2020/2/13.
//

#import <UIKit/UIKit.h>
#import "CJPayUIMacro.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayBDPayMainMessageViewStyle) {
    CJPayBDPayMainMessageViewStyleNone,
    CJPayBDPayMainMessageViewStyleArrow
};

typedef void (^CJPayBDPayMainMessageViewArrowBlock)(void);

@interface CJPayBDPayMainMessageView : UIView<CJPayBaseLoadingProtocol>

@property (nonatomic, assign) CJPayBDPayMainMessageViewStyle style;
@property (nonatomic, copy) CJPayBDPayMainMessageViewArrowBlock arrowBlock;
@property (nonatomic, assign) BOOL enable;

- (void)updateTitleLabelText:(NSString *)title;
- (void)updateDescLabelText:(NSString *)desc;
- (void)updateWithIconUrl:(NSString *)iconUrl;
- (void)updateSubDescLabelText:(NSString *)subDesc;
- (void)updateWithVoucher:(NSArray *) vouchers;

@end

NS_ASSUME_NONNULL_END
