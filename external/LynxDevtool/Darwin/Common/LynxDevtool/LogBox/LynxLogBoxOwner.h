//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxLogBoxHelper.h"
#import "LynxLogBoxProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxLogBoxOwner : NSObject

+ (LynxLogBoxOwner *)getInstance;
- (void)insertLogBoxProxy:(LynxLogBoxProxy *)proxy withController:(UIViewController *)controller;
- (void)onNewLog:(nullable NSString *)message
       withLevel:(LynxLogBoxLevel)level
       withProxy:(LynxLogBoxProxy *)proxy;
- (void)onNewConsole:(nullable NSDictionary *)message withProxy:(LynxLogBoxProxy *)proxy;
- (void)showConsoleMsgsWithProxy:(LynxLogBoxProxy *)proxy;  // long press menu
- (void)updateTemplateUrl:(nullable NSString *)url withProxy:(LynxLogBoxProxy *)proxy;
- (void)reloadLynxViewWithProxy:(LynxLogBoxProxy *)proxy;  // long press or Page.reload

@end

NS_ASSUME_NONNULL_END
