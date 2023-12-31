//
//  BDXBridgeStatus.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/19.
//

#import <Foundation/Foundation.h>
#import "BDXBridgeDefinitions.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeStatus : NSObject

@property (nonatomic, assign) BDXBridgeStatusCode statusCode;
@property (nonatomic, copy, nullable) NSString *message;

+ (instancetype)statusWithStatusCode:(BDXBridgeStatusCode)statusCode message:(nullable NSString *)message, ...;
+ (instancetype)statusWithStatusCode:(BDXBridgeStatusCode)statusCode;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
