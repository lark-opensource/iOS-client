//
//  BDXBridgeResponder.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/22.
//

#import "BDXBridgeResponder.h"
#import "BDXBridgeMacros.h"
#import "BDXBridgeContainerProtocol.h"
#import <BDXServiceCenter/BDXPopupContainerProtocol.h>

@implementation BDXBridgeResponder

+ (void)closeContainer:(id<BDXBridgeContainerProtocol>)container animated:(BOOL)animated completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    if (![container isKindOfClass:UIResponder.class]) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeFailed message:@"The specified container is not kind of class UIResponder."];
        bdx_invoke_block(completionHandler, nil, status);
        return;
    }
    UIViewController *vc = [self viewControllerForResponder:(UIResponder *)container];
    if ([vc conformsToProtocol:@protocol(BDXPopupContainerProtocol)]) {
        BOOL closed = [(id <BDXPopupContainerProtocol>)vc close:nil];
        NSString *message = closed ? @"close successed" : @"close failed";
        BDXBridgeStatusCode statusCode = closed ? BDXBridgeStatusCodeSucceeded : BDXBridgeStatusCodeFailed;
        BDXBridgeStatus *status = statusCode == BDXBridgeStatusCodeSucceeded ? nil : [BDXBridgeStatus statusWithStatusCode:statusCode message:message];
        bdx_invoke_block(completionHandler, nil, status);
        return;
    }

    id<BDXBridgeRouteServiceProtocol> routeService = bdx_get_service(BDXBridgeRouteServiceProtocol);
    if ([routeService respondsToSelector:@selector(closeContainer:animated:completionHandler:)]) {
        [routeService closeContainer:container animated:animated completionHandler:completionHandler];
    } else {
        NSString *message = nil;
        BDXBridgeStatusCode statusCode = BDXBridgeStatusCodeSucceeded;
        UINavigationController *navVC = vc.navigationController;
        if (navVC) {
            NSMutableArray<UIViewController *> *vcs = [navVC.viewControllers mutableCopy];
            if ([vcs containsObject:vc]) {
                if ([vcs count] == 1 && vc.presentingViewController) {
                    [navVC dismissViewControllerAnimated:animated completion:nil];
                } else {
                    [vcs removeObject:vc];
                    [navVC setViewControllers:vcs animated:animated];
                }
            } else {
                statusCode = BDXBridgeStatusCodeNotFound;
                message = @"Can not find the container's view controller in current navigation stack.";
            }
        } else if (vc.presentingViewController) {
            [vc dismissViewControllerAnimated:animated completion:nil];
        } else {
            statusCode = BDXBridgeStatusCodeFailed;
            message = @"Failed to close the specified container.";
        }
        BDXBridgeStatus *status = statusCode == BDXBridgeStatusCodeSucceeded ? nil : [BDXBridgeStatus statusWithStatusCode:statusCode message:message];
        bdx_invoke_block(completionHandler, nil, status);
    }
}

+ (UIViewController *)viewControllerForResponder:(UIResponder *)responder
{
    UIViewController *vc = nil;
    UIResponder *nextResponder = responder;
    while (nextResponder) {
        if ([nextResponder isKindOfClass:UIViewController.class]) {
            vc = (UIViewController *)nextResponder;
            break;
        } else {
            nextResponder = nextResponder.nextResponder;
        }
    }
    return vc;
}

@end
