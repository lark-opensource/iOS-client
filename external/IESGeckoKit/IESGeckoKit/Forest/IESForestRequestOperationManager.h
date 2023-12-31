// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "IESForestRequestOperation.h"
#import "IESForestRequest.h"
#import "IESForestDefines.h"

@class IESForestKit;

NS_ASSUME_NONNULL_BEGIN

@interface IESForestRequestOperationManager : NSObject

@property (nonatomic, weak) IESForestKit *forestKit;

- (IESForestRequestOperation *)operationWithRequest:(IESForestRequest *)request;

- (void)removeOperation:(IESForestRequestOperation*)operation;

@end

NS_ASSUME_NONNULL_END
