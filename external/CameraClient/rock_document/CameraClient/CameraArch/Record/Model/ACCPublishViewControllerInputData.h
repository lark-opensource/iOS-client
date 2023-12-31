//
//  ACCPublishViewControllerInputData.h
//  Pods
//
//  Created by chengfei xiao on 2019/9/26.
//

#import <Foundation/Foundation.h>

#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CameraClient/AWEVideoPublishResponseModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditServiceProtocol;

@interface ACCPublishViewControllerInputData : NSObject

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) AWEResourceUploadParametersResponseModel *uploadParamsCache;

@end

NS_ASSUME_NONNULL_END
