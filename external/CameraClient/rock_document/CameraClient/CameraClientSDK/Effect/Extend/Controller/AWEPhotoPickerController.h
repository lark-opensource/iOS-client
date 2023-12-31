//
//  AWEPhotoPickerController.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/13.
//

#import <UIKit/UIKit.h>
#import <CameraClient/AWEPhotoPickerModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEPhotoPickerControllerDelegate;

/**
 * AR Matting, Pixaloop 道具的照片选择面板
 */
@interface AWEPhotoPickerController : UIViewController

@property (nonatomic, weak) id<AWEPhotoPickerControllerDelegate> delegate;

@property (nonatomic, strong, readonly) AWEPhotoPickerModel *photoPickerModel;

@property (nonatomic, strong) UIButton *circularFinishButton;
@property (nonatomic, strong) UIButton *rectangleFinishButton;

/**
 * `maxSelectionCount` and `minSelectionCount` are used for multi-asset selection.
 */
@property (nonatomic, assign) NSInteger maxSelectionCount;
@property (nonatomic, assign) NSInteger minSelectionCount;

- (instancetype)initWithResourceType:(AWEGetResourceType)resourceType
                enableMultiSelection:(BOOL)enableMultiSelection;

- (instancetype)init NS_UNAVAILABLE;
- (void)updateViewForExposedPanelLayoutManager:(BOOL)exposed;

@end

@protocol AWEPhotoPickerControllerDelegate <NSObject>

/**
 * Did select/deselect an asset from the photoPicker panel.
 */
- (void)photoPickerController:(AWEPhotoPickerController *)photoPickerController didSelectAsset:(AWEAssetModel * _Nullable)asset atIndex:(NSInteger)index;

/**
 * Did select to open the Photo Album View Controller.
 */
- (void)photoPickerControllerDidSelectPlusButton:(AWEPhotoPickerController *)photoPickerController;

@optional

/**
 * @brief Did click multi-asset finish selection button.
 */
- (void)photoPickerController:(AWEPhotoPickerController *)photoPickerController didClickMultiSelectionFinishButton:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
