//
//  CJPayUniteSignContentView.h
//  CJPay-9aff3e34
//
//  Created by 王新华 on 2022/9/15.
//

#import <UIKit/UIKit.h>
#import "CJPaySignRequestUtil.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayTrackerProtocol;

@class CJPayDefaultChannelShowConfig;
@protocol CJPaySignDataProtocol <NSObject>

@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate;

/// 绑定数据
/// @param info 具体数据，类型目前不定
- (void)bindData:(CJPayTypeInfo *)info;

/// 返回当前选择的支付方式。包括特定的支付渠道和绑定新卡等，均在此回调。具体的业务流程由外部处理
- (CJPayDefaultChannelShowConfig *)currentChoosePayMethod;

@end

@interface CJPayUniteSignContentView : UIView<CJPaySignDataProtocol>



@end

NS_ASSUME_NONNULL_END
