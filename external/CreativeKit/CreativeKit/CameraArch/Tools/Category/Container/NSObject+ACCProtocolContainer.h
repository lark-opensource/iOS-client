//
//  NSObject+ACCProtocolContainer.h
//  ByteDanceKit
//
//  Created by Howie He on 2021-05-08.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ACCProtocolContainer)

- (nullable id)acc_getProtocol:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END