//
//  UITextField+BDPExtension.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import <UIKit/UIKit.h>

@interface UITextField (BDPExtension)

// 获取文字选中部分
- (NSRange)bdp_selectedRange;

// 设置键盘选中部分 - ***必须在键盘弹起后才能生效***
- (void)setBdp_selectedRange:(NSRange)bdp_selectedRange;

@end
