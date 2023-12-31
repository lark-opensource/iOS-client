//
//  HMDUploadProtocol.h
//  Article
//
//  Created by fengyadong on 17/5/3.
//
//

#import <Foundation/Foundation.h>

@class HMDNetworkReqModel;
@class HMDNetworkUploadModel;
/**
 *  JSON网络请求回调
 *
 *  @param error    错误
 *  @param jsonObj  返回的json对象
 */
typedef void (^HMDNetworkJSONFinishBlock)(NSError *error, id jsonObj);

/**
 网络请求回调

 @param error 错误
 @param data 数据
 @param response 响应
 */
typedef void (^HMDNetworkDataResponseBlock)(NSError *error, id data, NSURLResponse *response);

@protocol HMDNetworkProtocol<NSObject>

//http request api group
- (void)asyncRequestWithModel:(HMDNetworkReqModel *)model callBackWithResponse:(HMDNetworkDataResponseBlock)callBackWithResponse;
//http upload api group
- (void)uploadWithModel:(HMDNetworkUploadModel *)model callBackWithResponse:(HMDNetworkDataResponseBlock)callBackWithResponse;

@optional
//http request api group
- (void)asyncRequestWithModel:(HMDNetworkReqModel *)model callback:(HMDNetworkJSONFinishBlock)callback;
//http upload api group
- (void)uploadWithModel:(HMDNetworkUploadModel *)model callback:(HMDNetworkJSONFinishBlock)callback;

@end
