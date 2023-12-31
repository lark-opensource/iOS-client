//
//  CJPayBizWebViewController+H5Notification.h
//  CJPay
//
//  Created by liyu on 2020/1/16.
//

#import "CJPayBizWebViewController.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kH5CommunicationNotification = @"com.bytedance.cjpay.H5Notification";

@interface CJPayBizWebViewController (H5Notification)

@property (nullable, nonatomic, copy) NSDictionary *dataSentByH5;

- (void)registerH5Notification;

@end

NS_ASSUME_NONNULL_END
