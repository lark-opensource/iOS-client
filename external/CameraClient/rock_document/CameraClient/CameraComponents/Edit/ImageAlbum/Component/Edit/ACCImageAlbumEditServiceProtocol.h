//
//  ACCImageAlbumEditServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/4/22.
//

#ifndef ACCImageAlbumEditServiceProtocol_h
#define ACCImageAlbumEditServiceProtocol_h

#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCImageAlbumEditServiceProtocol <NSObject>

@property (nonatomic, assign, readonly) BOOL isImageScrollGuideAllowed;

@property (nonatomic, strong, readonly) RACSignal *scrollGuideDidDisappearSignal;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCImageAlbumEditServiceProtocol_h */
