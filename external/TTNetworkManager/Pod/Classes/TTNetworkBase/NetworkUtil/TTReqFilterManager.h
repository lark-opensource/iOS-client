//
//  TTReqFilterManager.h
//  Pods
//
//  Created by changxing on 2019/9/2.
//  Request & response interceptor, the interceptor is executed synchronously
//

#import "TTHttpRequest.h"
#import "TTHttpResponse.h"
#import "TTNetworkManager.h"

@interface TTReqFilterManager : NSObject {
    NSMutableArray *requestFilters;
    NSMutableArray *responseFilters;
    NSMutableArray *responseChainFilters;
    NSMutableArray *responseMutableDataFilters;
    NSMutableArray<TTRequestFilterObject *> *requestObjectFilters;
    NSMutableArray<TTResponseFilterObject *> *responseObjectFilters;
    NSMutableArray<TTResponseChainFilterObject *> *responseChainObjectFilters;
    NSMutableArray<TTResponseMutableDataFilterObject *> *responseMutableDataObjectFilters;
    NSMutableSet<NSString *> *requestObjectNameSet;
    NSMutableSet<NSString *> *responseObjectNameSet;
    NSMutableArray<TTRedirectFilterObject *> *redirectObjectFilters;
    NSMutableSet<NSString *> *redirectObjectNameSet;
}

+ (instancetype)shareInstance;

/**
 * Whether to start the interceptor
 */
@property(nonatomic, assign) BOOL enableReqFilter;

/**
 * request Interceptor added
 */
- (void)addRequestFilterBlock:(RequestFilterBlock) requestFilterBlock;

/**
 *  remove request filter
 */
- (void)removeRequestFilterBlock:(RequestFilterBlock)requestFilterBlock;

/**
 * response Interceptor added
 */
-(void)addResponseFilterBlock:(ResponseFilterBlock) responseFilterBlock;

/**
 *  remove response filter
 */
- (void)removeResponseFilterBlock:(ResponseFilterBlock)responseFilterBlock;

/**
 * response Interceptor added，can modify Error
 */
- (void)addResponseChainFilterBlock:(ResponseChainFilterBlock) responseChainFilterBlock;

/**
 *  remove response chain filter
 */
- (void)removeResponseChainFilterBlock:(ResponseChainFilterBlock)responseChainFilterBlock;


- (void)addResponseMutableDataFilterBlock:(ResponseMutableDataFilterBlock)responseMutableDataFilterBlock;

- (void)removeResponseMutableDataFilterBlock:(ResponseMutableDataFilterBlock)responseMutableDataFilterBlock;

#pragma mark - add and remove new request and response filter object
- (BOOL)addRequestFilterObject:(TTRequestFilterObject *)requestFilterObject;

- (void)removeRequestFilterObject:(TTRequestFilterObject *)requestFilterObject;

- (BOOL)addResponseFilterObject:(TTResponseFilterObject *)responseFilterObject;

- (void)removeResponseFilterObject:(TTResponseFilterObject *)responseFilterObject;

- (BOOL)addResponseChainFilterObject:(TTResponseChainFilterObject *)responseChainFilterObject;

- (void)removeResponseChainFilterObject:(TTResponseChainFilterObject *)responseChainFilterObject;

- (BOOL)addResponseMutableDataFilterObject:(TTResponseMutableDataFilterObject *)responseMutableDataFilterObject;

- (void)removeResponseMutableDataFilterObject:(TTResponseMutableDataFilterObject *)responseMutableDataFilterObject;

- (BOOL)addRedirectFilterObject:(TTRedirectFilterObject *)redirectFilterObject;

- (void)removeRedirectFilterObject:(TTRedirectFilterObject *)redirectFilterObject;

- (void)runRequestFilter:(TTHttpRequest *) request;

- (void)runResponseFilter:(TTHttpRequest *) request
                 response:(TTHttpResponse *)response
                     data:(id) data
            responseError:(NSError **)responseError;

- (void)runResponseMutableDataFilter:(TTHttpRequest *)request
                     response:(TTHttpResponse *)response
                         data:(NSData **)data
                responseError:(NSError **)responseError;

- (void)runRedirectFilter:(TTRedirectTask *)redirect_task
                  request:(TTHttpRequest *)request;

- (void)dealloc;

@end
