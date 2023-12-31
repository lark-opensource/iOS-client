//
//  CJPayIDCardLast6DigitsInputView.h
//  CJPay
//
//  Created by liyu on 2020/3/24.
//

#import <UIKit/UIKit.h>

@class CJPayBaseSafeInputView;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayIDCardLast6DigitsInputView : UIView

@property (nonatomic, strong, readonly) CJPayBaseSafeInputView *textField;

@property (nonatomic, strong) UIColor *cursorColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, copy, nullable) void (^completion)(NSString *);
@property (nonatomic, copy, nullable) void (^didStartInputBlock)(void);

@end

NS_ASSUME_NONNULL_END
