//
//  BDXContainerUtil.m
//  BDXContainer
//
//  Created by xinwen tan on 2021/4/7.
//

#import "BDXContainerUtil.h"
#import <BDXServiceCenter/BDXPageContainerProtocol.h>
#import <BDXServiceCenter/BDXPopupContainerProtocol.h>
#import <ByteDanceKit/BTDResponder.h>

NS_ASSUME_NONNULL_BEGIN

@implementation BDXContainerUtil

+ (nullable UIViewController<BDXContainerProtocol> *)topBDXViewController
{
    UIViewController *top = [BTDResponder topViewController];
    if ([top conformsToProtocol:@protocol(BDXPopupContainerProtocol)]) {
        return (UIViewController<BDXPopupContainerProtocol> *)top;
    }
    if ([top conformsToProtocol:@protocol(BDXPageContainerProtocol)]) {
        UIViewController<BDXPageContainerProtocol> *vc = (UIViewController<BDXPageContainerProtocol> *)top;
        __auto_type childViewControllers = vc.childViewControllers;
        for (int i = childViewControllers.count - 1; i >= 0; i--) {
            __auto_type child = childViewControllers[i];
            if ([child conformsToProtocol:@protocol(BDXPopupContainerProtocol)]) {
                return (UIViewController<BDXPopupContainerProtocol> *)child;
            }
        }
        return vc;
    }
    return nil;
}

@end

NS_ASSUME_NONNULL_END
