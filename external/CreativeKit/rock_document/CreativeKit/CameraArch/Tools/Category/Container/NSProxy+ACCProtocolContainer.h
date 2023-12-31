//
//  NSProxy+ACCProtocolContainer.h
//  CreationKit
//
//  Created by Howie He on 2021-05-08.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSProxy (ACCProtocolContainer)

- (nullable id)acc_getProtocol:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END