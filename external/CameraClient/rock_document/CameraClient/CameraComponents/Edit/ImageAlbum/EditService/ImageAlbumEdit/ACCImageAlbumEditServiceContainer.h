//
//  ACCImageAlbumEditServiceContainer.h
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2021/3/10.
//

#import <IESInject/IESInject.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCBusinessInputData;
@protocol ACCUIViewControllerProtocol;

@interface ACCImageAlbumEditServiceContainer: IESStaticContainer

@property (nonatomic, weak, readonly) id<ACCBusinessInputData> inputData;
@property (nonatomic, weak, readonly) id<ACCUIViewControllerProtocol> viewController;

@end

NS_ASSUME_NONNULL_END
