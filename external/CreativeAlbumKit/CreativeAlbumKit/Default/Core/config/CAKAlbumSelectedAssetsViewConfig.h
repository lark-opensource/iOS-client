//
//  CAKAlbumSelectedAssetsViewConfig.h
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by yuanchang on 2020/12/21.
//

#import <Foundation/Foundation.h>

@interface CAKAlbumSelectedAssetsViewConfig : NSObject

@property (nonatomic, assign) BOOL shouldHideSelectedAssetsViewWhenNotSelect;

//for preview page
@property (nonatomic, assign) BOOL enableSelectedAssetsViewForPreviewPage;
@property (nonatomic, assign) BOOL shouldHideSelectedAssetsViewWhenNotSelectForPreviewPage;
/// enable drag to move asset in selected assetes view for preview page
@property (nonatomic, assign) BOOL enableDragToMoveForSelectedAssetsViewInPreviewPage;
/// enable drag to move asset in selected assetes view for multi-select page
@property (nonatomic, assign) BOOL enableDragToMoveForSelectedAssetsView;

@end
