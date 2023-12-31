//
//  CJPayByteSecondaryPayMethodCreditPayCell.h
//  Pods
//
//  Created by bytedance on 2021/7/29.
//

#import <UIKit/UIKit.h>
#import "CJPayMehtodDataUpdateProtocol.h"
#import "CJPayBytePayMethodSecondaryCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayByteSecondaryPayMethodCreditPayCell : CJPayBytePayMethodSecondaryCell<CJPayMethodDataUpdateProtocol>

@property (nonatomic, copy) void(^clickBlock)(NSString *installment);

@end

NS_ASSUME_NONNULL_END
