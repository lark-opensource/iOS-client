//
//  CJPayHomePageAmountView.h
//  Pods
//
//  Created by xiuyuanLee on 2021/4/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayHomePageAmountView : UIView

- (void)updateWithTotalAmount:(NSString *)totalAmount withDetailInfo:(NSString *)detailInfo;
- (void)updateTextColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
