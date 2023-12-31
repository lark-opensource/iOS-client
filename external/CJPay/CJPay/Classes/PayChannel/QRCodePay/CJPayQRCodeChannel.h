//
//  CJPayQRCodeChannel.h
//  CJPay-Example
//
//  Created by 易培淮 on 2020/10/28.
//

#import "CJPayBasicChannel.h"
#import "CJPayQRCodeViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayQRCodeChannel : CJPayBasicChannel

@property (nonatomic, weak) CJPayQRCodeViewController *QRCodeVC;
@property (nonatomic, weak) id<CJPayQRCodeChannelProtocol> delegate;

@end

NS_ASSUME_NONNULL_END
