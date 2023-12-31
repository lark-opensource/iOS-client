//
//  ACCBatchPublishServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/8/2.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel, AWEResourceUploadParametersResponseModel;

@protocol ACCBatchPublishServiceProtocol <NSObject>

#pragma mark - image album batch publish
- (BOOL)enableImageAlbumBatchStoryPublish:(AWEVideoPublishViewModel *)publishModel;
- (void)publishImageAlbumBatchStoryWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                  uploadParamsCache:(AWEResourceUploadParametersResponseModel *)uploadParamsCache;
@end

FOUNDATION_STATIC_INLINE id<ACCBatchPublishServiceProtocol> ACCBatchPublishService() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCBatchPublishServiceProtocol)];
}

NS_ASSUME_NONNULL_END
