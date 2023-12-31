//
//  OPTraceContextProtocol.h
//  LarkOPInterface
//
//  Created by changrong on 2020/9/14.
//

#import <Foundation/Foundation.h>
#import "OPTrace.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OPTraceContextProtocol <NSObject>

@required

- (nullable OPTrace *)opTrace;

@end

NS_ASSUME_NONNULL_END
