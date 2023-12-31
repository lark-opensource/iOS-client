//
//  NSObject+CJPay.m
//  Pods
//
//  Created by 王新华 on 2021/3/25.
//

#import "NSObject+CJPay.h"
#import "CJPayMonitor.h"
#import "CJPayUIMacro.h"
#import <objc/runtime.h>

@implementation NSObject(CJPay)

- (UIViewController *)cjpay_referViewController {
    UIViewController *vc;
    NSMapTable *obj = objc_getAssociatedObject(self, @selector(cjpay_referViewController));
    id referVC = [obj objectForKey:@"cjpay_referViewController"];
    if ([referVC isKindOfClass:UIViewController.class]) {
        vc = (UIViewController *)referVC;
    }
    if (!vc && CJ_Pad) {
        NSString *desc = [self description] ?: @"";
        [CJMonitor trackService:@"wallet_refer_vc_exception" extra:@{@"desc": desc}];
    }
    return vc;
}

- (void)setCjpay_referViewController:(UIViewController *)cjpay_referViewController {
    NSMapTable *mapTable = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
    [mapTable setObject:cjpay_referViewController forKey:@"cjpay_referViewController"];
    objc_setAssociatedObject(self, @selector(cjpay_referViewController), mapTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)cjpay_wrapperReferViewController:(UIViewController *)referViewController {
    self.cjpay_referViewController = referViewController;
    return self;
}

@end
