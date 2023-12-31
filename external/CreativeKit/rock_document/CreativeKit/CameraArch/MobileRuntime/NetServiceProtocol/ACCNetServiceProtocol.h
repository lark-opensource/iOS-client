//
//  ACCNetServiceProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/25.
//

#import <Foundation/Foundation.h>
#import "ACCServiceLocator.h"
#import "ACCRequestModel.h"


NS_ASSUME_NONNULL_BEGIN

typedef void (^ACCRequestModelBlock)(ACCRequestModel * _Nullable requestModel);

typedef void (^ACCNetServiceCompletionBlock)(id _Nullable model, NSError * _Nullable error);
typedef void (^ACCNetworkServiceDownloadProgressBlock)(CGFloat progress);
typedef void (^ACCNetworkServiceDownloadComletionBlock)(NSURLResponse * _Nullable response, NSURL * _Nullable filePath, NSError * _Nullable error);


@protocol ACCNetServiceProtocol <NSObject>

- (NSDictionary *)commonParameters;

- (NSString *)defaultDomain;

- (NSError *)invalidParameterError;
#pragma mark - get/post

- (id)GET:(NSString *)urlString
    params:(NSDictionary *_Nullable)params
modelClass:(Class _Nullable)objectClass
completion:(ACCNetServiceCompletionBlock _Nullable)block;

- (id)POST:(NSString *)urlString
    params:(NSDictionary *_Nullable)params
modelClass:(Class _Nullable)objectClass
completion:(ACCNetServiceCompletionBlock _Nullable)block;

- (id)useJSONrequestSerializerPOST:(NSString *)urlString
                            params:(NSDictionary *_Nullable)params
                        modelClass:(Class _Nullable)objectClass
                        completion:(ACCNetServiceCompletionBlock _Nullable)block;

- (id)requestWithModel:(ACCRequestModelBlock)requestModelBlock completion:(ACCNetServiceCompletionBlock _Nullable)block;

#pragma mark - upload

- (id)uploadWithModel:(ACCRequestModelBlock)requestModelBlock
             progress:(NSProgress *_Nullable __autoreleasing *_Nullable)progress
           completion:(ACCNetServiceCompletionBlock _Nullable)block;

#pragma mark - download

- (void)downloadWithModel:(ACCRequestModelBlock)requestModelBlock
            progressBlock:(ACCNetworkServiceDownloadProgressBlock _Nullable)progressBlock
               completion:(ACCNetworkServiceDownloadComletionBlock)completionBlock;

- (void)downloadFileWithURL:(NSURL *)url
             destinationURL:(NSURL *)destinationURL
            supportTempFile:(BOOL)supportTempFile
                   progress:(ACCNetworkServiceDownloadProgressBlock)progressHandler
                 completion:(ACCNetworkServiceDownloadComletionBlock)completion;

#pragma mark - cancel
- (void)cancel:(id)request;

@optional

- (NSErrorDomain)apiErrorDomain;

- (NSErrorDomain)networkErrorDomain;

@end

FOUNDATION_STATIC_INLINE id<ACCNetServiceProtocol> ACCNetService() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCNetServiceProtocol)];
}

NS_ASSUME_NONNULL_END
