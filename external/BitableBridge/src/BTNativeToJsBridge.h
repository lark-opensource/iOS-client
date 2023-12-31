//
//  NativeToJsBridge.h
//  BitableBridge
//
//  Created by maxiao on 2018/9/13.
//

#import <Foundation/Foundation.h>
#import <React/RCTEventEmitter.h>

@interface BTNativeToJsBridge : RCTEventEmitter <RCTBridgeModule>

- (void)request:(NSString *)string;

- (void)docsRequest:(NSString *)string;

@end
