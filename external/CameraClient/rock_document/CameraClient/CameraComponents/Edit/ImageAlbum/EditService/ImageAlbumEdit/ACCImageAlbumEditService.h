//
//  ACCImageAlbumEditService.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/23.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESServiceProvider;

@interface ACCImageAlbumEditService : NSObject <ACCEditServiceProtocol>

- (void)configResolver:(id<IESServiceProvider>)resolver;

- (instancetype)initForPublish;

@end

NS_ASSUME_NONNULL_END
