//
//  CJPayBytePayMethodCreditPayCell.h
//  Pods
//
//  Created by bytedance on 2021/7/26.
//

#import <UIKit/UIKit.h>
#import "CJPayMehtodDataUpdateProtocol.h"
#import "CJPayBytePayMethodCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBytePayMethodCreditPayCell : CJPayBytePayMethodCell<CJPayMethodDataUpdateProtocol>

@property (nonatomic, copy) void(^clickBlock)(NSString *installment);

@end

NS_ASSUME_NONNULL_END
