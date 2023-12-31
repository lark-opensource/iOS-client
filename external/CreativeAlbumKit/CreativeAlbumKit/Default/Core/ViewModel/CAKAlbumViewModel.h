//
//  CAKAlbumViewModel.h
//  CameraClient
//
//  Created by lixingdong on 2020/6/17.
//

#import <Foundation/Foundation.h>
#import "CAKPhotoManager.h"

#import "CAKAlbumNavigationViewConfig.h"
#import "CAKAlbumBottomViewConfig.h"
#import "CAKAlbumSelectedAssetsViewConfig.h"
#import "CAKSelectedAssetsViewProtocol.h"
#import "CAKAlbumListViewControllerProtocol.h"
#import "CAKAlbumPreviewPageBottomViewProtocol.h"
#import "CAKAlbumBaseViewModel.h"
#import "CAKAlbumListBlankView.h"

@class CAKAlbumListViewController;

typedef NS_ENUM(NSUInteger, CAKAlbumPreviewAndMultiSelectType) {
    CAKAlbumPreviewAndMultiSelectTypeBothEnabled,
    CAKAlbumPreviewAndMultiSelectTypeBothDisabled,
    CAKAlbumPreviewAndMultiSelectTypeEnableMultiSelectDisablePreview, //enable multi select, disable preview
    CAKAlbumPreviewAndMultiSelectTypeEnablePreviewDisableMultiSelect, //enable preview, disable multi select
};

@interface CAKAlbumViewModel : CAKAlbumBaseViewModel

@property (nonatomic, strong, readonly, nullable) NSMutableArray<NSNumber *> *currentNilIndexArray;

@property (nonatomic, strong, nullable) CAKAlbumNavigationViewConfig *navigationViewConfig;
@property (nonatomic, strong, nullable) CAKAlbumBottomViewConfig *bottomViewConfig;
@property (nonatomic, strong, nullable) CAKAlbumSelectedAssetsViewConfig *selectedAssetsViewConfig;
@property (nonatomic, strong, nullable) UIView<CAKSelectedAssetsViewProtocol> *customAssetsViewForPreviewPage;
@property (nonatomic, assign) CGFloat previewBottomViewHeight;

@property (nonatomic, assign) BOOL enableBottomViewForPreviewPage;
@property (nonatomic, strong, nullable) UIView<CAKAlbumPreviewPageBottomViewProtocol> *customBottomViewForPreviewPage;

- (CAKAlbumPreviewAndMultiSelectType)previewAndMultiSelectTypeWithListViewController:(CAKAlbumListViewController * _Nullable)listViewController;

- (void)updateNilIndexArray:(NSMutableArray<NSNumber *> * _Nullable)nilIndexArray;

- (CAKAlbumListBlankViewType)blankViewTypeWithResourceType:(AWEGetResourceType)type;

@end
