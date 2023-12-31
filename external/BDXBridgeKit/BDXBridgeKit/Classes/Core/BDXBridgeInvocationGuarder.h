//
//  BDXBridgeInvocationGuarder.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeInvocationGuarder : NSObject

- (instancetype)initWithMessage:(NSString *)message;
- (void)invoke;

@end

NS_ASSUME_NONNULL_END
