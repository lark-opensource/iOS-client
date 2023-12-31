// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "IESForestRequest.h"
#import "IESForestDefines.h"

@class IESForestWorkflow;
@class IESForestKit;

NS_ASSUME_NONNULL_BEGIN

@interface IESForestRequestOperation : NSObject <IESForestRequestOperation>

@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) NSMutableArray *completions;

@property (nonatomic, strong) IESForestWorkflow *workflow;

- (instancetype)initWithRequest:(IESForestRequest *)request forestKit:(IESForestKit *)forestKit;

/// add compeltion to operation. NOTE: this methond is NOT thread safe
- (void)appendCompletion:(nullable IESForestCompletionHandler)completion;

- (BOOL)cancel;

@end

NS_ASSUME_NONNULL_END
