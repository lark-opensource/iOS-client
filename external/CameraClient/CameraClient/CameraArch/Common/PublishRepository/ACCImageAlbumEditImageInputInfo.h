//
//  ACCImageAlbumEditImageInputInfo.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/7.
//

#import <Foundation/Foundation.h>
#import <Mantle/MTLModel.h>
#import "ACCImageAlbumItemBaseResourceModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCImageAlbumEditImageInputInfo : ACCImageAlbumItemDraftResourceRestorableModel

ACCImageEditModeObjUsingCustomerInitOnly;

@property (nonatomic, copy) NSString *placeholderImageFilePath;

@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, assign) CGFloat imageScale;

@end

NS_ASSUME_NONNULL_END
