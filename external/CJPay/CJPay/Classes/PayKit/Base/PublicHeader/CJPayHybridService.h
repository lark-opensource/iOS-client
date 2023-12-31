//
//  CJPayHybridService.h
//  CJPay
//
//  Created by RenTongtong on 2023/7/28.
//

#import <Foundation/Foundation.h>
#import "CJPayDeskRouteDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayHybridService <NSObject>

- (void)openSchema:(NSString *)schema withInfo:(NSDictionary *)sdkInfo routeDelegate:(id<CJPayDeskRouteDelegate>)routeDelegate;

@end

NS_ASSUME_NONNULL_END

