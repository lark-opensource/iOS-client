//
//  TTLynxBridgeEngine.h
//  Pods
//
//  Created by momingqi on 2020/3/19.
//

#import <Foundation/Foundation.h>
#import <TTBridgeUnify/TTBridgeEngine.h>
#import <Lynx/LynxView.h>

NS_ASSUME_NONNULL_BEGIN

@class TTLynxBridgeEngine;

@interface LynxView (TTBridge)

@property (nonatomic, strong, readonly) TTLynxBridgeEngine *tt_engine;

- (void)tt_installBridgeEngine:(TTLynxBridgeEngine *)bridge;

@end


@interface TTLynxBridgeEngine : NSObject <TTBridgeEngine>

@property (nonatomic, weak, nullable, readonly) UIViewController *sourceController;
@property (nonatomic, strong, readonly, nullable) NSURL *sourceURL;
@property (nonatomic, weak, readonly) NSObject *sourceObject;

- (void)installOnLynxView:(LynxView *)lynxView;

@end

NS_ASSUME_NONNULL_END
