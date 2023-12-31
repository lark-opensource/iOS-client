//
//  UIViewController+AWECreativePath.m
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2021/1/18.
//

#import "UIViewController+AWECreativePath.h"
#import "ACCCreativePathManager.h"
#import "ACCCreativePathMessage.h"
#import <objc/runtime.h>
#import <HTSServiceKit/HTSMessageCenter.h>

@implementation UIViewController (AWECreativePath)
@dynamic awe_pathObserver;

- (UIViewController *)awe_pathObserver
{
    return objc_getAssociatedObject(self, @selector(awe_pathObserver));
}

- (void)setAwe_pathObserver:(UIViewController *)awe_pathObserver
{
    objc_setAssociatedObject(self, @selector(awe_pathObserver), awe_pathObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation AWECreativePathObserverViewController

- (BOOL)onWindow
{
    BOOL onWindow = NO;
    UIViewController *controller = self;
    while (controller.parentViewController) {
        controller = controller.parentViewController;
    }
    
    UIResponder *responder = controller;
    while (responder) {
        if ([responder isKindOfClass:[UIWindow class]]) {
            onWindow = YES;
            break;
        }
        responder = [responder nextResponder];
    }
    
    return onWindow;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    SAFECALL_MESSAGE(ACCCreativePathMessage, @selector(creativePathPageWillAppear:), creativePathPageWillAppear:self.page);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[ACCCreativePathManager manager] checkWindow];
    SAFECALL_MESSAGE(ACCCreativePathMessage, @selector(creativePathPageDidAppear:), creativePathPageDidAppear:self.page);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    SAFECALL_MESSAGE(ACCCreativePathMessage, @selector(creativePathPageWillDisappear:), creativePathPageWillDisappear:self.page);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[ACCCreativePathManager manager] checkWindow];
    SAFECALL_MESSAGE(ACCCreativePathMessage, @selector(creativePathPageDidDisappear:), creativePathPageDidDisappear:self.page);
}

@end
