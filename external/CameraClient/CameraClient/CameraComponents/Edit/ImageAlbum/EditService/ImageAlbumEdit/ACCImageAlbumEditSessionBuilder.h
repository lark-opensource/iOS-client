//
//  ACCImageAlbumEditSessionBuilder.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/23.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditSessionBuilderProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCEditViewControllerInputData, AWEVideoPublishViewModel;

@interface ACCImageAlbumEditSessionBuilder : NSObject <ACCEditSessionBuilderProtocol>

- (instancetype)initWithInputData:(ACCEditViewControllerInputData *)inputData;

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;


@end

NS_ASSUME_NONNULL_END
