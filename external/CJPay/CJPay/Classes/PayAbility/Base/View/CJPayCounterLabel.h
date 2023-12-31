//
//  CJPayCounterLabel.h
//  CJPay
//
//  Created by wangxiaohong on 2020/7/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString *_Nullable (^CJFormatBlock)(CGFloat currentNumber);
typedef NSAttributedString * _Nullable(^CJAttributedFormatBlock)(CGFloat currentNumber);

@interface CJPayCounterLabel : UILabel

- (void)cj_fromNumber:(CGFloat)startNumber
             toNumber:(CGFloat)endNumber
             duration:(CFTimeInterval)duration
               format:(CJFormatBlock)format;

- (void)cj_fromNumber:(CGFloat)startNumber
             toNumber:(CGFloat)endNumber
             duration:(CFTimeInterval)duration
     attributedFormat:(CJAttributedFormatBlock)format;

@end

NS_ASSUME_NONNULL_END
