//
//  ACCImageAlbumFlowViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/4/15.
//

#import "ACCEditViewModel.h"
#import "ACCImageAlbumFlowServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCImageAlbumFlowViewModel : ACCEditViewModel <ACCImageAlbumFlowServiceProtocol>

- (void)updateIsSwitchModeBubbleAllowed:(BOOL)allowed;

@end

NS_ASSUME_NONNULL_END
