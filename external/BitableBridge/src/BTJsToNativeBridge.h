//
//  JsToNativeBridge.h
//  BitableBridge
//
//  Created by maxiao on 2018/9/13.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@protocol JsToNativeBridgeDelegate<NSObject>
@optional
- (void)didReceivedResponse:(NSString *)dataString;
- (void)didReceivedDocsResponse:(NSString *)jsonString;

@end

@interface BTJsToNativeBridge : NSObject <RCTBridgeModule>

@property (weak, nonatomic) id<JsToNativeBridgeDelegate> delegate;

@end
