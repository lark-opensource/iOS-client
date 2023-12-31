//
//  AWEMattingView.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/5/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
@class AWEAssetModel;
@class AWEMattingView;

@protocol AWEMattingViewProtocol <NSObject>

- (void)didChooseImage:(UIImage *)image asset:(PHAsset *)asset;
- (void)albumPhotosChanged;
- (void)albumFaceImageDetectEmpty;
- (void)didPressPlusButton;

@optional

- (void)didChooseAssetModel:(AWEAssetModel *)assetModel isAlbumChange:(BOOL)isAlbumChange;
- (void)didChooseAssetModelArray:(NSArray<AWEAssetModel *> *)assetModelArray;
- (void)itemShouldBeSelected:(AWEAssetModel*)assetModel completion:(dispatch_block_t)completion;

- (void)mattingView:(AWEMattingView *)mattingView didSelectSubItem:(AWEAssetModel * _Nullable)asset;

@end

@class AWEAlbumPhotoCollector;

@interface AWEMattingView : UIView

@property (nonatomic, weak) id<AWEMattingViewProtocol> delegate;
@property (nonatomic, assign) BOOL showPixaloopPlusButton;
@property (nonatomic, strong) AWEAlbumPhotoCollector *photoCollector;
@property (nonatomic, strong, readonly) NSMutableArray <AWEAssetModel *> *selectedAssetArray;
@property (nonatomic, assign) BOOL enableMultiAssetsSelection;
@property (nonatomic, assign) NSInteger maxAssetsSelectionCount;
@property (nonatomic, assign) NSInteger minAssetsSelectionCount;

- (void)resetToInitState;

- (void)resetFaceDetectingStatus;
- (void)resumeFaceDetect;
- (void)cancelFaceDetect;

- (void)addPhotoLibraryChangeObserver;
- (void)unSelectCurrentCell;
/**
 * 更新当前选中的照片为assetLocalIdentifier的照片
 * 如果该照片在预览区，选中该照片并滑动到该位置
 * 如果该照片不在预览区，取消选中当前的照片
 */
- (void)updateSelectedPhotoWithAssetLocalIdentifier:(NSString *)assetLocalIdentifier;
- (void)updateSelectedAssetArray:(NSArray<AWEAssetModel *> *)selectedAssetArray;

@end
