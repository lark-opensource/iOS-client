//
//  IESBridgeMonitor.h
//  IESWebKit
//
//  Created by Lizhen Hu on 2020/1/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IESBridgeMessage;
@class IESBridgeMethod;

@interface IESBridgeMonitor : NSObject

+ (void)monitorJSBInvokeEventWithBridgeMessage:(IESBridgeMessage *)message bridgeMethod:(IESBridgeMethod *)method url:(NSURL *)url isAuthorized:(BOOL)isAuthorized;

@end

NS_ASSUME_NONNULL_END
