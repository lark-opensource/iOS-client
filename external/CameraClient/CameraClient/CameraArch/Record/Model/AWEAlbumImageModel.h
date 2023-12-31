//
//  AWEAlbumFaceModel.h
//  AWEStudio
//
//  Created by liubing on 2018/5/25.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <CameraClient/AWEAssetModel.h>

typedef NS_ENUM(NSInteger, AWEAlbumPhotoCollectorDetectResult) {
    AWEAlbumPhotoCollectorDetectResultUnmatch = 0,
    AWEAlbumPhotoCollectorDetectResultMatch   = 1,
    AWEAlbumPhotoCollectorDetectResultPerfectMatch   = 2,
};

@interface AWEAlbumImageModel : NSObject
#pragma mark - Memory

@property (nonatomic, strong) UIImage *image;

#pragma mark - Disk

@property (nonatomic, copy) NSString *assetLocalIdentifier;
@property (nonatomic, strong)  AWEAssetModel* asset;
@property (nonatomic, assign) AWEAlbumPhotoCollectorDetectResult detectResult;

#pragma mark - PHImageRequestOptions Info

@property (nonatomic, assign) BOOL networkAccessAllowed;

@end
