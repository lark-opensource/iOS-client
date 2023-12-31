// Copyright 2020 The Lynx Authors. All rights reserved.

#import "LynxDevMenu.h"
#if OS_IOS
#import <UIKit/UIKit.h>
#elif OS_OSX
#import <AppKit/AppKit.h>
#endif

#pragma mark - LynxDevMenuItem
@implementation LynxDevMenuItem {
  NSString* _title;
  dispatch_block_t _handler;
}

- (instancetype)initWithTitle:(NSString*)title handler:(dispatch_block_t)handler {
  if (self = [super init]) {
    _title = title;
    _handler = handler;
  }
  return self;
}

+ (instancetype)buttonItemWithTitle:(NSString*)title handler:(dispatch_block_t)handler {
  return [[self alloc] initWithTitle:title handler:handler];
}

- (void)callHandler {
  if (_handler) {
    _handler();
  }
}

- (NSString*)title {
  if (_title) return _title;
  return nil;
}

@end

#pragma mark - LynxDevMenu
@implementation LynxDevMenu {
#if OS_IOS
  UIAlertController* _actionSheet;
#elif OS_OSX
  NSAlert* _actionSheet;
#endif
  __weak LynxInspectorOwner* _owner;
  LynxDevMenuShowConsoleBlock _showConsoleBlock;
}

- (instancetype)initWithInspectorOwner:(LynxInspectorOwner*)owner {
  if (self = [super init]) {
    _owner = owner;
  }
  return self;
}

- (BOOL)isActionSheetShown {
  return _actionSheet != nil;
}

- (NSArray<LynxDevMenuItem*>*)menuItemsToPresent {
  NSMutableArray<LynxDevMenuItem*>* items = [NSMutableArray new];
  [items addObject:[LynxDevMenuItem buttonItemWithTitle:@"Reload"
                                                handler:^{
                                                  [self reload];
                                                }]];
  if (_showConsoleBlock) {
    [items addObject:[LynxDevMenuItem buttonItemWithTitle:@"Console"
                                                  handler:^{
                                                    [self showConsole];
                                                  }]];
  }

  return items;
}

#if OS_IOS
typedef void (^LynxDevMenuAlertActionHandler)(UIAlertAction* action);

- (void)show {
  NSString* deviceType = [UIDevice currentDevice].model;
  _actionSheet = [UIAlertController alertControllerWithTitle:@"Lynx Debug Menu"
                                                     message:@""
                                              preferredStyle:[deviceType isEqualToString:@"iPhone"]
                                                                 ? UIAlertControllerStyleActionSheet
                                                                 : UIAlertControllerStyleAlert];
  NSArray<LynxDevMenuItem*>* items = [self menuItemsToPresent];
  for (LynxDevMenuItem* item in items) {
    [_actionSheet
        addAction:[UIAlertAction actionWithTitle:item.title
                                           style:UIAlertActionStyleDefault
                                         handler:[self alertActionHandlerForDevItem:item]]];
  }
  [_actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                   style:UIAlertActionStyleCancel
                                                 handler:[self alertActionHandlerForDevItem:nil]]];

  UIViewController* controller = [UIApplication sharedApplication].keyWindow.rootViewController;
  UIViewController* presentedController = controller.presentedViewController;
  while (presentedController && ![presentedController isBeingDismissed]) {
    controller = presentedController;
    presentedController = controller.presentedViewController;
  }
  [controller presentViewController:_actionSheet animated:YES completion:nil];
}

- (LynxDevMenuAlertActionHandler)alertActionHandlerForDevItem:(LynxDevMenuItem* __nullable)item {
  return ^(__unused UIAlertAction* action) {
    if (item) {
      [item callHandler];
    }
    self->_actionSheet = nil;
  };
}
#elif OS_OSX
- (void)show {
  _actionSheet = [[NSAlert alloc] init];
  [_actionSheet setMessageText:@"Lynx Debug Menu"];
  NSArray<LynxDevMenuItem*>* items = [self menuItemsToPresent];
  for (LynxDevMenuItem* item in items) {
    [_actionSheet addButtonWithTitle:item.title];
  }
  [_actionSheet addButtonWithTitle:@"Cancel"];
  [_actionSheet beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow
                       completionHandler:^(NSModalResponse returnCode) {
                         NSUInteger i = returnCode - NSAlertFirstButtonReturn;
                         if (i < items.count) {
                           LynxDevMenuItem* item = items[i];
                           [item callHandler];
                         }
                       }];
}
#endif

- (void)setShowConsoleBlock:(LynxDevMenuShowConsoleBlock)block {
  _showConsoleBlock = block;
}

- (void)reload {
  [_owner reloadLynxView:false];
}

- (void)showConsole {
  if (_showConsoleBlock) {
    _showConsoleBlock();
  }
}

@end
