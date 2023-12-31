//
//  ACCPublishServiceProtocol.h
//  CameraClient
//
//  Created by wishes on 2019/12/9.
//

#ifndef ACCPublishServiceProtocol_h
#define ACCPublishServiceProtocol_h

#import <Foundation/Foundation.h>
#import <CameraClient/AWEVideoPublishResponseModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPublishNetServiceProtocol <NSObject>

/*
*  获取上传需要的参数
*/
- (void)requestUploadParametersWithCompletion:(void (^)(AWEResourceUploadParametersResponseModel * _Nullable model, NSError * _Nullable error))completion;

- (void)requestUploadParametersWithParameters:(nullable NSDictionary *)params completion:(void (^)(AWEResourceUploadParametersResponseModel * _Nullable model, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END


#endif /* ACCPublishServiceProtocol_h */
