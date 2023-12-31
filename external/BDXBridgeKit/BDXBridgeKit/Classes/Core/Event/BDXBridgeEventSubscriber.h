//
//  BDXBridgeEventSubscriber.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/9/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^BDXBridgeEventCallback)(NSString *eventName, NSDictionary * _Nullable params);

@protocol BDXBridgeContainerProtocol;
@class BDXBridgeEvent;

@interface BDXBridgeEventSubscriber : NSObject

@property (nonatomic, assign, readonly) NSTimeInterval timestamp;

// Used by the frontend side.
+ (instancetype)subscriberWithContainer:(id<BDXBridgeContainerProtocol>)container timestamp:(NSTimeInterval)timestamp;

// Used by the native side.
+ (instancetype)subscriberWithCallback:(BDXBridgeEventCallback)callback;

@end

NS_ASSUME_NONNULL_END
