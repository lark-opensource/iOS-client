//
//  TTReqFilterManager.h
//  Pods
//
//  Created by changxing on 2019/9/2.
//
//

#import "TTReqFilterManager.h"
#import "TTNetworkManagerLog.h"

@implementation TTReqFilterManager {
    dispatch_queue_t concurrentBarrierQueue;
}

+ (instancetype)shareInstance {
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (id)init {
    self = [super init];
    if (self) {
        requestFilters = [NSMutableArray array];
        responseFilters = [NSMutableArray array];
        responseChainFilters = [NSMutableArray array];
        responseMutableDataFilters = [NSMutableArray array];
        requestObjectFilters = [NSMutableArray array];
        responseObjectFilters = [NSMutableArray array];
        responseChainObjectFilters = [NSMutableArray array];
        responseMutableDataObjectFilters = [NSMutableArray array];
        requestObjectNameSet = [NSMutableSet set];
        responseObjectNameSet = [NSMutableSet set];
        redirectObjectFilters = [NSMutableArray array];
        redirectObjectNameSet = [NSMutableSet set];
        concurrentBarrierQueue = dispatch_queue_create("com.ttnetfilter.barrier", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

#pragma mark - add and remove filters
- (void)addRequestFilterBlock:(RequestFilterBlock) requestFilterBlock {
    if (!_enableReqFilter) {
        return;
    }

    dispatch_barrier_async(concurrentBarrierQueue, ^{
        //add self-> to solve warning:
        //"Block implicitly retains 'self'; explicitly mention 'self' to indicate this is intended behavior"
        [self->requestFilters addObject:requestFilterBlock];
    });
}

- (void)removeRequestFilterBlock:(RequestFilterBlock) requestFilterBlock {
    if (!_enableReqFilter) {
        return;
    }
    
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->requestFilters removeObject:requestFilterBlock];
    });
}

- (void)addResponseFilterBlock:(ResponseFilterBlock) responseFilterBlock {
    if (!_enableReqFilter) {
        return;
    }

    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->responseFilters addObject:responseFilterBlock];
    });
}

- (void)removeResponseFilterBlock:(ResponseFilterBlock) responseFilterBlock {
    if (!_enableReqFilter) {
        return;
    }

    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->responseFilters removeObject:responseFilterBlock];
    });
}

- (void)addResponseChainFilterBlock:(ResponseChainFilterBlock) responseChainFilterBlock {
    if (!_enableReqFilter) {
        return;
    }

    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->responseChainFilters addObject:responseChainFilterBlock];
    });
}

- (void)removeResponseChainFilterBlock:(ResponseChainFilterBlock) responseChainFilterBlock {
    if (!_enableReqFilter) {
        return;
    }

    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->responseChainFilters removeObject:responseChainFilterBlock];
    });
}

- (void)addResponseMutableDataFilterBlock:(ResponseMutableDataFilterBlock)responseMutableDataFilterBlock {
    if (!_enableReqFilter) {
        LOGI(@"enableReqFilter disabled");
        return;
    }
    
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->responseMutableDataFilters addObject:responseMutableDataFilterBlock];
    });
}

- (void)removeResponseMutableDataFilterBlock:(ResponseMutableDataFilterBlock)responseMutableDataFilterBlock {
    if (!_enableReqFilter) {
        LOGI(@"enableReqFilter disabled");
        return;
    }
    
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->responseMutableDataFilters removeObject:responseMutableDataFilterBlock];
    });
}

#pragma mark - add and remove new request and response filter object
- (BOOL)addRequestFilterObject:(TTRequestFilterObject *)requestFilterObject {
    if (!_enableReqFilter) {
        return NO;
    }
    
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        BOOL alreadyExist = [self->requestObjectNameSet containsObject:requestFilterObject.requestFilterName];
        NSAssert(alreadyExist == NO, @"request filter object %@ already exist", requestFilterObject.requestFilterName);
        if (!alreadyExist) {
            [self->requestObjectNameSet addObject:requestFilterObject.requestFilterName];
            [self->requestObjectFilters addObject:requestFilterObject];
        }
    });
    return YES;
}

- (void)removeRequestFilterObject:(TTRequestFilterObject *)requestFilterObject {
    if (!_enableReqFilter) {
        return;
    }
    
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->requestObjectNameSet removeObject:requestFilterObject.requestFilterName];
        [self->requestObjectFilters removeObject:requestFilterObject];
    });
}

- (BOOL)addResponseFilterObject:(TTResponseFilterObject *)responseFilterObject {
    if (!_enableReqFilter) {
        return NO;
    }
    
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        BOOL alreadyExist = [self->responseObjectNameSet containsObject:responseFilterObject.responseFilterName];
        NSAssert(alreadyExist == NO, @"response filter object %@ already exist", responseFilterObject.responseFilterName);
        if (!alreadyExist) {
            [self->responseObjectNameSet addObject:responseFilterObject.responseFilterName];
            [self->responseObjectFilters addObject:responseFilterObject];
        }
    });
    return YES;
}

- (void)removeResponseFilterObject:(TTResponseFilterObject *)responseFilterObject {
    if (!_enableReqFilter) {
        return;
    }
    
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->responseObjectNameSet removeObject:responseFilterObject.responseFilterName];
        [self->responseObjectFilters removeObject:responseFilterObject];
    });
}

- (BOOL)addResponseChainFilterObject:(TTResponseChainFilterObject *)responseChainFilterObject {
    if (!_enableReqFilter) {
        return NO;
    }
    
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        BOOL alreadyExist = [self->responseObjectNameSet containsObject:responseChainFilterObject.responseChainFilterName];
        NSAssert(alreadyExist == NO, @"response chain filter object %@ already exist", responseChainFilterObject.responseChainFilterName);
        if (!alreadyExist) {
            [self->responseObjectNameSet addObject:responseChainFilterObject.responseChainFilterName];
            [self->responseChainObjectFilters addObject:responseChainFilterObject];
        }
    });
    return YES;
}

- (void)removeResponseChainFilterObject:(TTResponseChainFilterObject *)responseChainFilterObject {
    if (!_enableReqFilter) {
        return;
    }
    
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->responseObjectNameSet removeObject:responseChainFilterObject.responseChainFilterName];
        [self->responseChainObjectFilters removeObject:responseChainFilterObject];
    });
}

- (BOOL)addResponseMutableDataFilterObject:(TTResponseMutableDataFilterObject *)responseMutableDataFilterObject {
    if (!_enableReqFilter) {
        return NO;
    }
    
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        BOOL alreadyExist = [self->responseObjectNameSet containsObject:responseMutableDataFilterObject.responseMutableDataFilterName];
        NSAssert(alreadyExist == NO, @"response mutable data filter object %@ already exist", responseMutableDataFilterObject.responseMutableDataFilterName);
        if (!alreadyExist) {
            [self->responseObjectNameSet addObject:responseMutableDataFilterObject.responseMutableDataFilterName];
            [self->responseMutableDataObjectFilters addObject:responseMutableDataFilterObject];
        }
    });
    return YES;
}

- (void)removeResponseMutableDataFilterObject:(TTResponseMutableDataFilterObject *)responseMutableDataFilterObject {
    if (!_enableReqFilter) {
        return;
    }
    
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->responseObjectNameSet removeObject:responseMutableDataFilterObject.responseMutableDataFilterName];
        [self->responseMutableDataObjectFilters removeObject:responseMutableDataFilterObject];
    });
}

- (BOOL)addRedirectFilterObject:(TTRedirectFilterObject *)redirectFilterObject {
    if (redirectFilterObject == nil) {
        return NO;
    }

    dispatch_barrier_async(concurrentBarrierQueue, ^{
        BOOL alreadyExist = [self->redirectObjectNameSet containsObject:redirectFilterObject.redirectFilterName];
        NSAssert(alreadyExist == NO, @"redirect filter object %@ already exist", redirectFilterObject.redirectFilterName);
        if (!alreadyExist) {
            [self->redirectObjectNameSet addObject:redirectFilterObject.redirectFilterName];
            [self->redirectObjectFilters addObject:redirectFilterObject];
        }
    });
    return YES;
}

- (void)removeRedirectFilterObject:(TTRedirectFilterObject *)redirectFilterObject {
    dispatch_barrier_async(concurrentBarrierQueue, ^{
        [self->redirectObjectNameSet removeObject:redirectFilterObject.redirectFilterName];
        [self->redirectObjectFilters removeObject:redirectFilterObject];
    });
}

#pragma mark - run filters
- (void)runRequestFilter:(TTHttpRequest *) request {
    if (!_enableReqFilter) {
        return;
    }
    
    dispatch_sync(concurrentBarrierQueue, ^{
        for (RequestFilterBlock requestFilterBlock in requestFilters) {
            requestFilterBlock(request);
        }
        for (TTRequestFilterObject *filterObject in requestObjectFilters) {
            if (filterObject.requestFilterBlock) {
                NSDate *startTime = [NSDate date];
                filterObject.requestFilterBlock(request);
                NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startTime timeIntervalSinceNow]) * 1000];
                [request.filterObjectsTimeInfo setValue:elapsedTime forKey:filterObject.requestFilterName];
            }
        }
    });
}

- (void)runResponseFilter:(TTHttpRequest *) request
                 response:(TTHttpResponse *) response
                     data:(id) data
            responseError:(NSError **) responseError {
    if (!_enableReqFilter) {
        return;
    }
    //solve warning: block captures an autoreleasing out-parameter, which may result in use-after-free bugs
    __block __strong NSError *tmpResErr = *responseError;
    dispatch_sync(concurrentBarrierQueue, ^{
        for (ResponseFilterBlock responseFilterBlock in responseFilters) {
            responseFilterBlock(request, response, data, tmpResErr);
        }
        for (ResponseChainFilterBlock responseChainFilterBlock in responseChainFilters) {
            responseChainFilterBlock(request, response, data, &tmpResErr);
        }
        for (TTResponseFilterObject *filterObject in responseObjectFilters) {
            if (filterObject.responseFilterBlock) {
                NSDate *startTime = [NSDate date];
                filterObject.responseFilterBlock(request, response, data, tmpResErr);
                NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startTime timeIntervalSinceNow]) * 1000];
                [response.filterObjectsTimeInfo setValue:elapsedTime forKey:filterObject.responseFilterName];
            }
        }
        for (TTResponseChainFilterObject *filterObject in responseChainObjectFilters) {
            if (filterObject.responseChainFilterBlock) {
                NSDate *startTime = [NSDate date];
                filterObject.responseChainFilterBlock(request, response, data, &tmpResErr);
                NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startTime timeIntervalSinceNow]) * 1000];
                [response.filterObjectsTimeInfo setValue:elapsedTime forKey:filterObject.responseChainFilterName];
            }
        }
    });
    *responseError = tmpResErr;
}

- (void)runResponseMutableDataFilter:(TTHttpRequest *)request
                     response:(TTHttpResponse *)response
                         data:(NSData **)data
                responseError:(NSError **)responseError {
    if (!_enableReqFilter) {
        LOGI(@"enableReqFilter disabled");
        return;
    }
    
    //solve warning: block captures an autoreleasing out-parameter, which may result in use-after-free bugs
    __block NSError *tmpResErr = *responseError;
    __block NSData *tmpData = *data;
    dispatch_sync(concurrentBarrierQueue, ^{
        for (ResponseMutableDataFilterBlock responseMutableDataFilterBlock in responseMutableDataFilters) {
            responseMutableDataFilterBlock(request, response, &tmpData, &tmpResErr);
        }
        for (TTResponseMutableDataFilterObject *filterObject in responseMutableDataObjectFilters) {
            if (filterObject.responseMutableDataFilterBlock) {
                NSDate *startTime = [NSDate date];
                filterObject.responseMutableDataFilterBlock(request, response, &tmpData, &tmpResErr);
                NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startTime timeIntervalSinceNow]) * 1000];
                [response.filterObjectsTimeInfo setValue:elapsedTime forKey:filterObject.responseMutableDataFilterName];
            }
        }
    });
    *responseError = tmpResErr;
    *data = tmpData;
}

- (void)runRedirectFilter:(TTRedirectTask *)redirect_task
                  request:(TTHttpRequest *)request; {
    dispatch_sync(concurrentBarrierQueue, ^{
        for (TTRedirectFilterObject *filterObject in redirectObjectFilters) {
            NSDate *startTime = [NSDate date];
            filterObject.redirectFilterBlock(redirect_task);
            NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startTime timeIntervalSinceNow]) * 1000];
            [request.filterObjectsTimeInfo setValue:elapsedTime forKey:filterObject.redirectFilterName];
        }
    });
}

- (void)dealloc {
    
}

@end
