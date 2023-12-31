//
//  CJPayCurrentTheme.h
//  CJPay
//
//  Created by 王新华 on 2018/11/26.
//

#import <Foundation/Foundation.h>
#import "CJPayDeskTheme.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCurrentTheme : NSObject
@property (nonatomic, strong) CJPayDeskTheme *currentTheme;
@property (nonatomic, strong) CJPayDeskTheme *withDrawTheme;
@property (nonatomic, assign) NSInteger showStyle;

+ (instancetype)shared;

- (UIColor *)bgColor;

- (UIColor *)fontColor;

@end

NS_ASSUME_NONNULL_END
