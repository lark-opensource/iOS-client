//
//  UIViewController+TSAddition.m
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/19.
//

#import "UIViewController+TSAddition.h"

#import "NSObject+TSAddition.h"
#import "TSPrivacyKitConstants.h"

@implementation UIViewController (TSAddition)

+ (void)tspk_preload {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self ts_swizzleInstanceMethod:@selector(viewDidLoad) with:@selector(tspk_viewDidLoad)];
        [self ts_swizzleInstanceMethod:@selector(viewDidAppear:) with:@selector(tspk_viewDidAppear:)];
        [self ts_swizzleInstanceMethod:@selector(viewDidDisappear:) with:@selector(tspk_viewDidDisappear:)];
        [self ts_swizzleInstanceMethod:@selector(viewWillAppear:) with:@selector(tspk_viewWillAppear:)];
        [self ts_swizzleInstanceMethod:@selector(viewWillDisappear:) with:@selector(tspk_viewWillDisappear:)];
        SEL deallocSEL = NSSelectorFromString(@"dealloc");
        [self ts_swizzleInstanceMethod:deallocSEL with:@selector(tspk_dealloc)];
    });
}

- (void)tspk_dealloc {
    if (![self tspk_isContainerViewController]) {
        [self tspk_postNotificationWithName:TSPKViewDealloc];
    }
    
    [self tspk_dealloc];
}

- (void)tspk_viewDidLoad {
    [self tspk_viewDidLoad];
    
    if (![self tspk_isContainerViewController]) {
        [self tspk_postNotificationWithName:TSPKViewDidLoad];
    }
}

- (void)tspk_viewDidAppear:(BOOL)animated {
    [self tspk_viewDidAppear:animated];
    
    if (![self tspk_isContainerViewController]) {
        [self tspk_postNotificationWithName:TSPKViewDidAppear];
    }
    
}

- (void)tspk_viewWillAppear:(BOOL)animated {
    [self tspk_viewWillAppear:animated];
    
    if (![self tspk_isContainerViewController]) {
        [self tspk_postNotificationWithName:TSPKViewWillAppear];
    }
}

- (void)tspk_viewDidDisappear:(BOOL)animated {
    [self tspk_viewDidDisappear:animated];
    
    if (![self tspk_isContainerViewController]) {
        [self tspk_postNotificationWithName:TSPKViewDidDisappear];
    }
}

- (void)tspk_viewWillDisappear:(BOOL)animated {
    [self tspk_viewWillDisappear:animated];
    
    if (![self tspk_isContainerViewController]) {
        [self tspk_postNotificationWithName:TSPKViewWillDisappear];
    }
}

- (void)tspk_postNotificationWithName:(NSString *)name {
    [self tspk_postNotificationWithName:name pageName:[self ts_className]];
}


- (void)tspk_postNotificationWithName:(NSString *)name pageName:(NSString *)pageName {
    [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                        object:nil
                                                      userInfo:@{
        TSPKPageNameKey: pageName
    }];
}

- (BOOL)tspk_isContainerViewController {
    return [self isKindOfClass:[UINavigationController class]] || [self isKindOfClass:[UITabBarController class]];
}

@end
