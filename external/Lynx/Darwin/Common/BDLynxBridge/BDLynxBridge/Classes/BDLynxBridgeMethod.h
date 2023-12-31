//
//  BDLynxBridgeMethod.h
//  BDLynxBridge
//
//  Created by li keliang on 2020/3/8.
//

#import <Foundation/Foundation.h>
#import "BDLynxBridgeDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDLynxBridgeMethod : NSObject

@property(nonatomic, copy, readonly) BDLynxBridgeHandler handler;
@property(nonatomic, copy, readonly) BDLynxBridgeSessionHandler sessionHandler;
@property(nonatomic, copy, readonly) NSString *namescope;
@property(nonatomic, copy, readonly) NSString *methodName;

- (instancetype)initWithMethodName:(NSString *)methodName
                           handler:(BDLynxBridgeHandler)handler
                    sessionHandler:(BDLynxBridgeSessionHandler)sessionHandler
                         namescope:(NSString *)namescope;

@end

NS_ASSUME_NONNULL_END
