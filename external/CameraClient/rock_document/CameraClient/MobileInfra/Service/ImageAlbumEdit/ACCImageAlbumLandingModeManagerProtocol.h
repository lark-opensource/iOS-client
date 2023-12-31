//
//  ACCImageAlbumLandingModeManagerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/4/14.
//

#ifndef ACCImageAlbumLandingModeManagerProtocol_h
#define ACCImageAlbumLandingModeManagerProtocol_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCImageAlbumLandingModeManagerProtocol <NSObject>

+ (void)markUsedImageAlbumMode;

+ (void)markUsedPhotoVideoMode;

+ (void)markUsedSmartMovieMode;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCImageAlbumLandingModeManagerProtocol_h */
