//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

#import "DownStreamListener.h"
#import "LynxView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxCanvasDownStreamManager : NSObject

+ (instancetype)sharedInstance;

- (NSInteger)addDownStreamListenerForView:(LynxView *)view
                                   withId:(NSString *)canvasId
                                    width:(NSInteger)width
                                   height:(NSInteger)height
                              AndListener:(id<DownStreamListener>)listener;

- (void)removeDownStreamListenerForView:(LynxView *)view
                                 withId:(NSString *)canvasId
                          AndListenerId:(NSInteger)listenerId;

@end

NS_ASSUME_NONNULL_END
