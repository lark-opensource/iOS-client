//
//  UIViewController+HMDUITrackerHookConfilictTest
//  HeimdallrDemoTests
//
//  Created by sunrunwang on 2020/8/4.
//  Copyright © 2020 sunrunwang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDProtector.h"
#import "HMDDynamicCall.h"
#import "HMDSwizzle.h"
#import "UIViewController+HMDUITracker.h"
#import "Aspects.h"
#import "Stinger.h"

static NSUInteger UIViewController_viewWillDisappear_calledTimes;
static NSUInteger Aspect_viewWillDisappear_calledTimes;

static NSUInteger UIViewController_viewDidDisappear_calledTimes;
static NSUInteger Aspect_viewDidDisappear_calledTimes;

static NSUInteger UIViewController_presentViewController_calledTimes;
static NSUInteger Stinger_presentViewController_calledTimes;

static NSUInteger UIViewController_dismissViewController_calledTimes;
static NSUInteger Stinger_dismissViewController_calledTimes;

static IMP original_viewWillDisappear;
static IMP original_viewDidDisappear;
static IMP original_presentViewController;
static IMP original_dismissViewController;

static void UIViewController_viewWillDisappear_replaced(id thisSelf, SEL sel, BOOL flag) {
    ((void (*)(id, SEL, BOOL))original_viewWillDisappear)(thisSelf, sel, flag);
    printf("[UIViewController] viewWillDisappear:\n");
    UIViewController_viewWillDisappear_calledTimes += 1;
}

static void UIViewController_viewDidDisappear_replaced(id thisSelf, SEL sel, BOOL flag) {
    ((void (*)(id, SEL, BOOL))original_viewDidDisappear)(thisSelf, sel, flag);
    printf("[UIViewController] viewDidDisappear:\n");
    UIViewController_viewDidDisappear_calledTimes += 1;
}

static void UIViewController_presentViewController_replaced(id thisSelf, SEL sel, UIViewController *vc, BOOL flag, void(^completion)(void)) {
    ((void (*)(id, SEL, UIViewController *, BOOL, void(^)(void)))original_presentViewController)(thisSelf, sel, vc, flag, completion);
    printf("[UIViewController] presentViewController:\n");
    UIViewController_presentViewController_calledTimes += 1;
}

static void UIViewController_dismissViewController_replaced(id thisSelf, SEL sel, BOOL flag, void(^completion)(void)) {
    ((void (*)(id, SEL, BOOL, void(^)(void)))original_dismissViewController)(thisSelf, sel, flag, completion);
    printf("[UIViewController] dismissViewController:\n");
    UIViewController_dismissViewController_calledTimes += 1;
}

@interface CAViewController3 : UIViewController

@end

@interface UIViewControllerHMDUITrackerHookConfilictTest : XCTestCase

@end

@implementation UIViewControllerHMDUITrackerHookConfilictTest

+ (void)setUp {
    original_viewWillDisappear = class_replaceMethod(UIViewController.class,
                                                     @selector(viewWillDisappear:),
                                                     (IMP)UIViewController_viewWillDisappear_replaced,
                                                     method_getTypeEncoding(class_getInstanceMethod(UIViewController.class,
                                                                                                    @selector(viewWillDisappear:))));
    original_viewDidDisappear = class_replaceMethod(UIViewController.class,
                                                    @selector(viewDidDisappear:),
                                                    (IMP)UIViewController_viewDidDisappear_replaced,
                                                    method_getTypeEncoding(class_getInstanceMethod(UIViewController.class,
                                                                                                   @selector(viewDidDisappear:))));
    original_presentViewController = class_replaceMethod(UIViewController.class,
                                                         @selector(presentViewController:animated:completion:),
                                                         (IMP)UIViewController_presentViewController_replaced,
                                                         method_getTypeEncoding(class_getInstanceMethod(UIViewController.class,
                                                                                                        @selector(presentViewController:animated:completion:))));
    original_dismissViewController = class_replaceMethod(UIViewController.class,
                                                         @selector(dismissViewControllerAnimated:completion:),
                                                         (IMP)UIViewController_dismissViewController_replaced,
                                                         method_getTypeEncoding(class_getInstanceMethod(UIViewController.class,
                                                                                                        @selector(dismissViewControllerAnimated:completion:))));
    [UIViewController aspect_hookSelector:@selector(viewWillDisappear:)
                              withOptions:AspectPositionBefore
                               usingBlock:^(id<AspectInfo> info, BOOL animated) {
        printf("[Aspect] viewWillDisappear:\n");
        Aspect_viewWillDisappear_calledTimes += 1;
    } error:nil];
    
    [UIViewController st_hookInstanceMethod:@selector(presentViewController:animated:completion:)
                                withOptions:STOptionBefore
                                 usingBlock:^(id<StingerParams> param, UIViewController *vc, BOOL flag, void(^completion)(void)){
        printf("[Stinger] presentViewController:\n");
        Stinger_presentViewController_calledTimes += 1;
    } error:nil];
    
    [UIViewController hmd_startSwizzle];
    
    [UIViewController st_hookInstanceMethod:@selector(dismissViewControllerAnimated:completion:)
                                withOptions:STOptionBefore
                                 usingBlock:^(id<StingerParams> param, BOOL flag, void(^completion)(void)){
        printf("[Stinger] dismissViewController:\n");
        Stinger_dismissViewController_calledTimes += 1;
    } error:nil];
    
    [UIViewController aspect_hookSelector:@selector(viewDidDisappear:)
                              withOptions:AspectPositionBefore
                               usingBlock:^(id<AspectInfo> info, BOOL animated) {
        printf("[Aspect] viewDidDisappear:\n");
        Aspect_viewDidDisappear_calledTimes += 1;
    } error:nil];
}

- (void)test_AspectSwizzleConfilict {
    __kindof UIViewController *vc = [[CAViewController3 alloc] initWithNibName:nil bundle:nil];
    
    UIViewController_viewWillDisappear_calledTimes = 0;
    Aspect_viewWillDisappear_calledTimes = 0;
    [vc viewWillDisappear:YES];
    XCTAssert(UIViewController_viewWillDisappear_calledTimes == 1);
    XCTAssert(Aspect_viewWillDisappear_calledTimes == 1);
    
    UIViewController_viewDidDisappear_calledTimes = 0;
    Aspect_viewDidDisappear_calledTimes = 0;
    [vc viewDidDisappear:YES];
    XCTAssert(UIViewController_viewDidDisappear_calledTimes == 1);
    XCTAssert(Aspect_viewDidDisappear_calledTimes == 1);
    
    UIViewController_presentViewController_calledTimes = 0;
    Stinger_presentViewController_calledTimes = 0;
    [vc presentViewController:UIViewController.new animated:YES completion:nil];
    XCTAssert(UIViewController_presentViewController_calledTimes == 1);
    XCTAssert(Stinger_presentViewController_calledTimes == 1);
    
    UIViewController_dismissViewController_calledTimes = 0;
    Stinger_dismissViewController_calledTimes = 0;
    [vc dismissViewControllerAnimated:YES completion:nil];
    XCTAssert(UIViewController_dismissViewController_calledTimes == 1);
    XCTAssert(Stinger_dismissViewController_calledTimes == 1);
    
    vc = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    
    UIViewController_viewWillDisappear_calledTimes = 0;
    Aspect_viewWillDisappear_calledTimes = 0;
    [vc viewWillDisappear:YES];
    XCTAssert(UIViewController_viewWillDisappear_calledTimes == 1);
    XCTAssert(Aspect_viewWillDisappear_calledTimes == 1);
    
    UIViewController_viewDidDisappear_calledTimes = 0;
    Aspect_viewDidDisappear_calledTimes = 0;
    [vc viewDidDisappear:YES];
    XCTAssert(UIViewController_viewDidDisappear_calledTimes == 1);
    XCTAssert(Aspect_viewDidDisappear_calledTimes == 1);
    
    UIViewController_presentViewController_calledTimes = 0;
    Stinger_presentViewController_calledTimes = 0;
    [vc presentViewController:UIViewController.new animated:YES completion:nil];
    XCTAssert(UIViewController_presentViewController_calledTimes == 1);
    XCTAssert(Stinger_presentViewController_calledTimes == 1);
    
    UIViewController_dismissViewController_calledTimes = 0;
    Stinger_dismissViewController_calledTimes = 0;
    [vc dismissViewControllerAnimated:YES completion:nil];
    XCTAssert(UIViewController_dismissViewController_calledTimes == 1);
    XCTAssert(Stinger_dismissViewController_calledTimes == 1);
}

@end

@implementation CAViewController3

@end
