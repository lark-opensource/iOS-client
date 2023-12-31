// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LynxUICanvas;

@interface LynxCanvasView : UIView

@property(nonatomic, weak) LynxUICanvas *ui;

- (void)setId:(NSString *)id;
- (void)frameDidChange;
- (bool)dispatchTouch:(NSString *const)touchType
              touches:(NSSet<UITouch *> *)touches
            withEvent:(UIEvent *)event;
- (void)onLayoutUpdate:(NSInteger)left
                 right:(NSInteger)right
                   top:(NSInteger)top
                bottom:(NSInteger)bottom
                 width:(NSInteger)width
                height:(NSInteger)height;

- (void)freeCanvasMemory;
- (void)restoreCanvasView;

@end

NS_ASSUME_NONNULL_END
