//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxDevtoolToast.h"

@interface LynxDevtoolToast ()

#if OS_IOS
@property(readwrite, nonatomic) UIAlertController* alert;
#elif OS_OSX
@property(readwrite, nonatomic) NSAlert* alert;
#endif

@end

@implementation LynxDevtoolToast

- (instancetype)initWithMessage:(NSString*)message {
  if (self = [super init]) {
#if OS_IOS
    self.alert = [UIAlertController alertControllerWithTitle:nil
                                                     message:message
                                              preferredStyle:UIAlertControllerStyleAlert];
#elif OS_OSX
    self.alert = [[NSAlert alloc] init];
    [self.alert setInformativeText:message];
#endif
  }
  return self;
}

- (void)show {
#if OS_IOS
  UIViewController* controller = [UIApplication sharedApplication].keyWindow.rootViewController;
  UIViewController* presentedController = controller.presentedViewController;
  while (presentedController && ![presentedController isBeingDismissed]) {
    controller = presentedController;
    presentedController = controller.presentedViewController;
  }
  [controller presentViewController:self.alert animated:YES completion:nil];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [self.alert.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  });
#elif OS_OSX
  [self.alert runModal];
#endif
}

@end
