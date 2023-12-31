//
//  RtcObjcProxy.h
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/5/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RtcObjcProxyHandler)(void (NS_NOESCAPE ^)(void));

@interface RtcObjcProxy : NSProxy

@property (strong, nonatomic, readonly) id target;

- (instancetype)initWithTarget:(id)target handler:(RtcObjcProxyHandler)handler;

@end

NS_ASSUME_NONNULL_END
