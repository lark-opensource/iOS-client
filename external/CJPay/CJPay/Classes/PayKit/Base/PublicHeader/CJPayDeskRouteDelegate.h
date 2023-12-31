//
//  CJPayDeskRouteDelegate.h
//  CJPay
//
//  Created by RenTongtong on 2023/8/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayDeskRouteDelegate <NSObject>

- (void)routeToVC:(nonnull UIViewController *)vc animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

