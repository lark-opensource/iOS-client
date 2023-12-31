//
//  CJPaySMSInputView.h
//  CJPay
//
//  Created by wangxinhua on 2020/8/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPaySMSInputViewDelegate <NSObject>

- (void)didFinishInputSMS:(NSString *)content;
- (void)didDeleteLastSMS;

@end

// 该view布局不包括两侧Margin。在设置frame时，只需要指定输入框的数量，以及输入框高度，输入框之间的间距即可。view内部会自动进行计算

@interface CJPaySMSInputView : UIView

@property (nonatomic, weak) id<CJPaySMSInputViewDelegate> smsInputDelegate;
@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, assign) CGFloat sep;
@property (nonatomic, assign) NSInteger inputFieldCount;
@property (nonatomic, strong) UIFont *font;

- (NSString *)getText;
- (void)clearText;

@end

NS_ASSUME_NONNULL_END

