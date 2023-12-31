//
//  CJPayDeskTheme.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/27.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

@interface CJPayDeskTheme : JSONModel <NSCoding>

@property (nonatomic,copy)NSString *bgColorString;
@property (nonatomic,copy)NSString *fontColorString;

// 确认支付按钮的圆角大小
@property (nonatomic,copy)NSString *confirmButtonShapeStr;
// 订单金额的文字颜色
@property (nonatomic,copy)NSString *amountColorStr;
// 订单名称的文字颜色
@property (nonatomic,copy)NSString *tradeNameColorStr;
// 支付方式"标签"背景色
@property (nonatomic,copy)NSString *payTypeMarkColorStr;
// 支付方式"标签"形状
@property (nonatomic,copy)NSString *payTypeMarkShapeStr;
// 支付方式"标签"类型
@property (nonatomic,copy)NSString *payTypeMarkStyleStr;
// 支付方式副标题颜色
@property (nonatomic,copy)NSString *payTypeMsgColorStr;


- (UIColor *)bgColor;

- (UIColor *)disableBgColor;

- (UIColor *)fontColor;

- (NSInteger)confirmButtonShape;

- (UIColor *)amountColor;

- (UIColor *)tradeNameColor;

- (UIColor *)payTypeMarkColor;

- (NSInteger)payTypeMarkShape;

- (NSString *)payTypeMarkStyle;

- (UIColor *)payTypeMsgColor;

@end
