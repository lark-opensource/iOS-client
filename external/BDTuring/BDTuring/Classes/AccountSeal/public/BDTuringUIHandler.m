//
//  BDTuringUIHandler.m
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringUIHandler.h"
#import "BDTuringAlertOption.h"

@implementation BDTuringUIHandler

+ (instancetype)sharedInstance {
    static BDTuringUIHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                   options:(NSArray<BDTuringAlertOption *> *)options
          onViewController:(UIViewController *)viewController {
    __strong typeof(self.handler) handler = self.handler;
    if (handler != nil) {
        [handler showAlertWithTitle:title
                            message:message
                            options:options
                   onViewController:viewController];
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    for (BDTuringAlertOption *option in options) {
        [alertController addAction:[UIAlertAction actionWithTitle:option.title style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [option triggerAction];
        }]];
    }
    
    [viewController presentViewController:alertController animated:YES completion:nil];
}

@end
