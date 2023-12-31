//
//  TTURLDispatch.h
//  TTNetworkManager
//
//  Created by taoyiyuan on 2020/11/6.
//

#import <Foundation/Foundation.h>
#import "TTDispatchResult.h"

@interface TTURLDispatch : NSObject

@property(nonatomic, copy) NSString *originalUrl;

@property(nonatomic, copy) NSString *requestTag;

@property(nonatomic, strong) dispatch_semaphore_t semaphore;

@property(nonatomic, strong) TTDispatchResult *result;

@property (nonatomic, assign) int32_t delayTimeMils;;

- (id)initWithUrl:(NSString*)url requestTag:(NSString*)requestTag;

- (void)await;

- (void)delayAwait;

- (void)resume;

- (void)doDispatch;

- (void)doDelay;

@end
