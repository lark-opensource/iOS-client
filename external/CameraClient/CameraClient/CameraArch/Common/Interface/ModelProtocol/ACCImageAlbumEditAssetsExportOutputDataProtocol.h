//
//  ACCImageAlbumEditAssetsExportOutputDataProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/4/13.
//

#ifndef ACCImageAlbumEditAssetsExportOutputDataProtocol_h
#define ACCImageAlbumEditAssetsExportOutputDataProtocol_h

@class ACCImageAlbumEditImageInputInfo;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCImageAlbumEditAssetsExportOutputDataProtocol <NSObject>

/// 原图(max = 1080p)
@property (nonatomic, copy) NSArray <ACCImageAlbumEditImageInputInfo *> *originalImages;

/// 备份图
@property (nonatomic, copy) NSArray <ACCImageAlbumEditImageInputInfo *> *backupImages;

/// 审核图(size <= 64k)
@property (nonatomic, copy) NSArray <ACCImageAlbumEditImageInputInfo *> *compressedFramsImages;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCImageAlbumEditAssetsExportOutputDataProtocol_h */
