//
//  ACCQuickAlbumExportProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by fengming.shi on 2020/12/14 15:38.
//	Copyright © 2020 Bytedance. All rights reserved.

#import <Foundation/Foundation.h>

@class AWEAssetModel;
@class AWEVideoPublishViewModel;

@protocol ACCQuickAlbumExportProtocol <NSObject>

- (void)exportVideoToEditing:(NSArray<AWEAssetModel *> *)assetModels
                publishModel:(AWEVideoPublishViewModel *)publishModel;

- (void)handleLocationInfosForQuickAlbumVideo:(NSMutableArray *)locationInfos;

@end
