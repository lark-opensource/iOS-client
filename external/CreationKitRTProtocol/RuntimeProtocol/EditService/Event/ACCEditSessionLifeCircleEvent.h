//
//  ACCEditSessionLifeCircleEvent.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2020/12/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditServiceProtocol;

@protocol ACCEditSessionLifeCircleEvent <NSObject>

@optional

- (void)onCreateEditSessionCompletedWithEditService:(id<ACCEditServiceProtocol>)editService;

// Will only be executed once based on the first frame callback
- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService;

// Will be executed multiple times according to the scene
- (void)executeSceneFirstRenderWithEditService:(id<ACCEditServiceProtocol>)editService;

- (void)failedToPlayWithEditService:(id<ACCEditServiceProtocol>)editService;

@end

NS_ASSUME_NONNULL_END
