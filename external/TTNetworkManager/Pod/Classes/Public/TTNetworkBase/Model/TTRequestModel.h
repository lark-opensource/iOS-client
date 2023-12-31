//
//  TTRequestModel.h
//  Pods
//
//  Created by ZhangLeonardo on 15/9/6.
//
//  TTRequestModel is a model structure for HTTP request requests, and is the basis for future scripting of network requests.
//  One idea is that after the server has designed the API, it is defined through IDL,
//  and then the IDL is translated into Python, ObjC, Java and other codes through scripts for use on various platforms.
//
//  If there is no IDL, it is not recommended to model to request API.
//

#import <Foundation/Foundation.h>
#import "TTNetworkDefine.h"


@interface TTRequestModel : NSObject

/**
 *  baseURL of request
 */
@property(nonatomic, strong) NSString * _host;

/**
 *  URL of request，can exclude host and schema
 */
@property(nonatomic, strong) NSString * _uri;

/**
 *  Method of request, GET by default
 */
@property(nonatomic, strong) NSString * _method;

/**
 *  request parameters
 */
@property(nonatomic, copy) NSDictionary * _params;

/**
 *  The response class corresponding to the requestModel. If the responseModel serializer is used, the value cannot be empty
 */
@property(nonatomic, strong) NSString * _response;

/**
 *  If you need to upload content with files and titles, use this block to construct
 */
@property(nonatomic, copy) TTConstructingBodyBlock _bodyBlock;

/**
 *  No common parameters are needed, the default is NO, if set to YES, no common parameters are added when constructing the URL
 */
@property(nonatomic, assign) BOOL _isNoNeedCommonParams;

/**
 *  common parameters needed by some api
 */
@property(nonatomic, strong) NSDictionary * _additionGetParams;

/**
 * store full url string when host is replaced in concurrent request
 */
@property(nonatomic, copy) NSString * _fullNewURL;

/**
 *  URI string after parameters replaced
 *
 *  @return URI string after parameters replaced
 */
- (NSString *)_requestURIStr;

/**
 *  URL constructed according to baseURL and uri
 *
 *  @return request URL
 */
- (NSURL *)_requestURL;

/**
 *  request parameters
 *
 *  @return request parameters
 */
- (NSDictionary *)_requestParams;

/**
 *  request method, this value is returned from method
 *
 *  @return request method
 */
- (NSString *)_requestMethod;

@end


