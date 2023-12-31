//
//  CJPayClosePayDeskAlertProtocol.h
//  Pods
//
//  Created by mengxin on 2021/4/6.
//

#ifndef CJPayClosePayDeskAlertProtocol_h
#define CJPayClosePayDeskAlertProtocol_h

@protocol CJPayClosePayDeskAlertProtocol <NSObject>

- (void)showDetainmentAlertWithVC:(UIViewController *)vc completion:(void(^)(BOOL isClose))completionBlock;

@end

#endif /* CJPayClosePayDeskAlertProtocol_h */
