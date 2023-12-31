//
//  CAKAlbumSectionModel.h
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/3.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CAKPhotoManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CAKAlbumAssetModel, CAKAlbumAssetDataModel;

@interface CAKAlbumSectionModel : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) AWEGetResourceType resourceType;
@property (nonatomic, strong) CAKAlbumAssetDataModel *assetDataModel;

@end

NS_ASSUME_NONNULL_END
