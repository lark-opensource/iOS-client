//
//  AWEMattingView.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/5/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeAlbumKit/CAKPhotoManager.h>
#import <Masonry/View+MASAdditions.h>

#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import "AWEAlbumImageModel.h"
#import "AWEAlbumPhotoCollector.h"
#import "AWEMattingView.h"
#import "AWEMattingCollectionViewCell.h"
#import "AWEVideoRecordOutputParameter.h"
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

static const CGFloat kACCFinishSelectionButtonEdgeWidth = 64.0;
static const CGFloat kACCFinishSelectionButtonEdgeHeight = 36.0;

@interface AWEMattingView () <UICollectionViewDataSource, UICollectionViewDelegate, PHPhotoLibraryChangeObserver, AWEAlbumPhotoCollectorObserver>

@property (nonatomic, strong) UIButton *plusButton;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) AWEAlbumImageModel *loadingFaceModel;
@property (nonatomic, assign) BOOL hasAddPhotoLibraryChangeObserver;
@property (nonatomic, strong) UIView *loadingView;
// The following two properties works together to support multi-assets selection.
@property (nonatomic, strong) UIButton *finishSelectionButton;
@property (nonatomic, strong, readwrite) NSMutableArray <AWEAssetModel *> *selectedAssetArray;

@end

@implementation AWEMattingView

- (void)dealloc
{
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    if (authorizationStatus == PHAuthorizationStatusAuthorized) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _hasAddPhotoLibraryChangeObserver = NO;
        [self addPhotoLibraryChangeObserver];
        self.layer.cornerRadius = 9;
        [self addSubviews];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        CGPoint stationPoint = [self.finishSelectionButton convertPoint:point fromView:self];
        if (CGRectContainsPoint(self.finishSelectionButton.bounds, stationPoint)) {
            view = self.finishSelectionButton;
        }
    }
    return view;
}

- (void)addPhotoLibraryChangeObserver
{
    if (!self.hasAddPhotoLibraryChangeObserver) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
            if (authorizationStatus == PHAuthorizationStatusAuthorized) {
                [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
                self.hasAddPhotoLibraryChangeObserver = YES;
            }
        });
    }
}

- (void)addSubviews
{
    [self addSubview:self.plusButton];
    self.plusButton.hidden = YES;
    
    [self addSubview:self.collectionView];
    ACCMasMaker(self.collectionView, {
        make.edges.equalTo(self);
    });

    
    self.collectionView.backgroundView = self.loadingView;
    self.loadingView.hidden = YES;

    [self addSubview:self.finishSelectionButton];
    ACCMasMaker(self.finishSelectionButton, {
        make.width.equalTo(@(kACCFinishSelectionButtonEdgeWidth));
        make.height.equalTo(@(kACCFinishSelectionButtonEdgeHeight));
        make.bottom.equalTo(self.mas_top).offset(-8);
        make.right.equalTo(self);
    });
    self.finishSelectionButton.hidden = YES;
}

#pragma mark - Getter & Setter

- (UIButton *)plusButton
{
    if (!_plusButton) {
        _plusButton = [[UIButton alloc] init];
        _plusButton.isAccessibilityElement = YES;
        _plusButton.accessibilityTraits = UIAccessibilityTraitNone;
        _plusButton.accessibilityLabel = @"进入相册选择页";
        [_plusButton setImage:ACCResourceImage(@"pixaloop_icon_upload") forState:UIControlStateNormal];
        [_plusButton addTarget:self action:@selector(onHeaderViewPlusButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _plusButton;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(48, 48);
        flowLayout.minimumInteritemSpacing = 8;
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 7.5, 0, 7.5);
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        if (@available(iOS 10.0, *)) {
            _collectionView.prefetchingEnabled = NO;
        }
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        [_collectionView registerClass:[AWEMattingCollectionViewCell class] forCellWithReuseIdentifier:[AWEMattingCollectionViewCell identifier]];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
    }
    return _collectionView;
}

- (UIView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[UIView alloc] init];
        
        UIView *loadingBackgroundView = [[UIView alloc] init];
        loadingBackgroundView.backgroundColor = ACCResourceColor(ACCUIColorBGContainer7);
        loadingBackgroundView.layer.cornerRadius = 4;
        loadingBackgroundView.layer.masksToBounds = YES;
        [_loadingView addSubview:loadingBackgroundView];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = ACCResourceImage(@"iconAlbumFaceLoadingView");
        [imageView acc_addRotateAnimationWithDuration:0.8f];
        [_loadingView addSubview:imageView];
        
        ACCMasMaker(loadingBackgroundView, {
            make.left.equalTo(_loadingView.mas_left).offset(7.5f);
            make.centerY.equalTo(_loadingView.mas_centerY);
            make.width.height.equalTo(@(50.0f));
        });
        
        ACCMasMaker(imageView, {
            make.center.equalTo(loadingBackgroundView);
        });
    }
    return _loadingView;
}

- (UIButton *)finishSelectionButton
{
    if (!_finishSelectionButton) {
        _finishSelectionButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _finishSelectionButton.backgroundColor = ACCResourceColor(ACCColorPrimary);
        [_finishSelectionButton setTitle:ACCLocalizedString(@"done", nil) forState:UIControlStateNormal];
        _finishSelectionButton.titleLabel.font = [UIFont acc_systemFontOfSize:15 weight:ACCFontWeightRegular];
        [_finishSelectionButton addTarget:self action:@selector(p_finishSelectionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        _finishSelectionButton.layer.cornerRadius = 2.0;
    }
    return _finishSelectionButton;
}

- (NSMutableArray<AWEAssetModel *> *)selectedAssetArray
{
    if (!_selectedAssetArray) {
        _selectedAssetArray = [NSMutableArray array];
    }
    return _selectedAssetArray;
}

- (void)setEnableMultiAssetsSelection:(BOOL)enableMultiAssetsSelection
{
    _enableMultiAssetsSelection = enableMultiAssetsSelection;
    self.finishSelectionButton.hidden = !enableMultiAssetsSelection;
    [self p_updateFinishSelectionButton];
}

- (void)setMinAssetsSelectionCount:(NSInteger)minAssetsSelectionCount
{
    _minAssetsSelectionCount = minAssetsSelectionCount;
    [self p_updateFinishSelectionButton];
}

- (void)setMaxAssetsSelectionCount:(NSInteger)maxAssetsSelectionCount
{
    _maxAssetsSelectionCount = maxAssetsSelectionCount;
    [self p_updateFinishSelectionButton];
}

- (void)unSelectCurrentCell {
    AWEMattingCollectionViewCell *selectedCell = (AWEMattingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
    selectedCell.customSelected = NO;
    self.selectedIndexPath = nil;
}


- (void)p_reset {
    AWEMattingCollectionViewCell *selectedCell = (AWEMattingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
    selectedCell.customSelected = NO;
    self.selectedIndexPath = nil;
    [self.collectionView setContentOffset:CGPointMake(0, 0) animated:NO];
    [self.delegate didChooseImage:nil asset:nil];
}

- (void)resetToInitState
{
    [self p_reset];
    if ([self.delegate respondsToSelector:@selector(didChooseAssetModel:isAlbumChange:)]) {
        [self.delegate didChooseAssetModel:nil isAlbumChange:NO];
    }
    if ([self.delegate respondsToSelector:@selector(didChooseAssetModelArray:)]) {
        [self.delegate didChooseAssetModelArray:nil];
    }
    // clear recorded data that is related to multi-assets selection
    [[self.selectedAssetArray copy] enumerateObjectsUsingBlock:^(AWEAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.selectedNum = nil;
    }];
    [self.selectedAssetArray removeAllObjects];
    self.finishSelectionButton.hidden = YES;
    self.enableMultiAssetsSelection = NO;
}

- (void)resetToInitStateCauseByAlbumChange
{
    [self p_reset];
    if ([self.delegate respondsToSelector:@selector(didChooseAssetModel:isAlbumChange:)]) {
          [self.delegate didChooseAssetModel:nil isAlbumChange:YES];
    }
}

- (void)resetFaceDetectingStatus
{
    [self.collectionView reloadData];
}

- (void)resumeFaceDetect
{
    [self.photoCollector startDetect];
}

- (void)cancelFaceDetect
{
    [self.photoCollector stopDetect];
}

- (void)setPhotoCollector:(AWEAlbumPhotoCollector *)photoCollector {
    if (_photoCollector != photoCollector) {
        _photoCollector.observer = nil;
        [_photoCollector stopDetect];
        _photoCollector = photoCollector;
        _photoCollector.observer = self;
        [self.collectionView reloadData];
        [self showLoading:YES];
        [_photoCollector startDetect];
    }
}

- (void)updateSelectedPhotoWithAssetLocalIdentifier:(NSString *)assetLocalIdentifier {
    if (!assetLocalIdentifier) {
        return;
    }
    
    __block NSIndexPath *indexPath = nil;
    [self.photoCollector.detectedResult enumerateObjectsUsingBlock:^(AWEAlbumImageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.assetLocalIdentifier isEqualToString:assetLocalIdentifier]) {
            indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
            *stop = YES;
        }
    }];
    
    self.selectedIndexPath = indexPath;
    [self.collectionView reloadData];
    if (indexPath) {
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}

- (void)updateSelectedAssetArray:(NSArray<AWEAssetModel *> *)selectedAssetArray
{
    if (!self.enableMultiAssetsSelection) {
        return;
    }
    // Clear the previously selected assets in matting view.
    [[self.selectedAssetArray copy] enumerateObjectsUsingBlock:^(AWEAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.selectedNum = nil;
    }];
    // Find the corresponding assets in matting view, and update their `selectedNum`.
    NSMutableArray<AWEAssetModel *> *mattingViewSelectedAssetArray = [NSMutableArray array];
    [[selectedAssetArray copy] enumerateObjectsUsingBlock:^(AWEAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.photoCollector.detectedResult enumerateObjectsUsingBlock:^(AWEAlbumImageModel * _Nonnull mattingViewObj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([mattingViewObj.assetLocalIdentifier isEqualToString:obj.asset.localIdentifier]) {
                mattingViewObj.asset.selectedNum = @(mattingViewSelectedAssetArray.count + 1);
                [mattingViewSelectedAssetArray addObject:mattingViewObj.asset];
                *stop = YES;
            }
        }];
    }];
    // Reload visible cells.
    self.selectedAssetArray = [mattingViewSelectedAssetArray mutableCopy];
    NSArray *visibleIndexPaths = [self.collectionView indexPathsForVisibleItems];
    [self.collectionView reloadItemsAtIndexPaths:visibleIndexPaths];
    [self p_updateFinishSelectionButton];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.photoCollector) {
        return self.photoCollector.detectedResult.count;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWEMattingCollectionViewCell *cell = (AWEMattingCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[AWEMattingCollectionViewCell identifier] forIndexPath:indexPath];
    if (self.selectedIndexPath && self.selectedIndexPath.section == indexPath.section && self.selectedIndexPath.item == indexPath.item) {
        cell.customSelected = YES;
    }
    AWEAlbumImageModel *faceModel = self.photoCollector.detectedResult[indexPath.item];
    cell.enableMultiAssetsSelection = self.enableMultiAssetsSelection;
    [cell configWithAlbumFaceModel:faceModel];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)p_collectionView:(UICollectionView *)collectionView singleAssetSelectionAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item >= self.photoCollector.detectedResult.count) {
        return;
    }
    AWEAlbumImageModel *faceModel = nil;
    if (self.selectedIndexPath) {
       if (indexPath.section == self.selectedIndexPath.section && indexPath.item == self.selectedIndexPath.item) {
           AWEMattingCollectionViewCell *cell = (AWEMattingCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
           cell.customSelected = NO;
           self.selectedIndexPath = nil;
       } else {
           AWEMattingCollectionViewCell *selectedCell = (AWEMattingCollectionViewCell *)[collectionView cellForItemAtIndexPath:self.selectedIndexPath];
           selectedCell.customSelected = NO;

           AWEMattingCollectionViewCell *cell = (AWEMattingCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
           cell.customSelected = YES;
           self.selectedIndexPath = indexPath;
           faceModel = self.photoCollector.detectedResult[indexPath.item];
       }
    } else {
       self.selectedIndexPath = indexPath;
       AWEMattingCollectionViewCell *cell = (AWEMattingCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
       cell.customSelected = YES;
       faceModel = self.photoCollector.detectedResult[indexPath.item];
    }

    if (faceModel) {
       if ([self.photoCollector.identifier hasPrefix:@"video_bg"]) {
           if ([self.delegate respondsToSelector:@selector(didChooseAssetModel:isAlbumChange:)]) {
               [self.delegate didChooseAssetModel:faceModel.asset isAlbumChange:NO];
           }
       } else {
           if (faceModel.assetLocalIdentifier) {
               PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[faceModel.assetLocalIdentifier] options:nil];
               PHAsset *asset = result.firstObject;
               if (asset) {
                   CGSize outputSize = [AWEVideoRecordOutputParameter maximumImportCompositionSize];
                   [CAKPhotoManager getUIImageWithPHAsset:asset imageSize:outputSize networkAccessAllowed:NO progressHandler:^(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info) {
                       AWELogToolError(AWELogToolTagImport, @"error: %@",error);
                   } completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                       if (isDegraded) return;
                       if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
                           [ACCToast() show: ACCLocalizedCurrentString(@"creation_icloud_download")];
                           [CAKPhotoManager getOriginalPhotoDataFromICloudWithAsset:asset progressHandler:^(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info) {
                               AWELogToolError(AWELogToolTagImport, @"error: %@",error);
                           } completion:nil];
                           return;
                       }
                       if (photo) {
                           [self.delegate didChooseImage:photo asset:asset];
                       } else {
                           [ACCToast() showError: ACCLocalizedCurrentString(@"com_mig_couldnt_access_icloud_photos")];
                       }
                   }];
               }
           }
       }
    } else {
       [self.delegate didChooseImage:nil asset:nil];
        if ([self.delegate respondsToSelector:@selector(didChooseAssetModel:isAlbumChange:)]) {
            [self.delegate didChooseAssetModel:nil isAlbumChange:NO];
        }
    }
}

- (void)p_collectionView:(UICollectionView *)collectionView multiAssetsSelectionAtIndexPath:(NSIndexPath *)indexPath
{
    AWEMattingCollectionViewCell *cell = (AWEMattingCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    NSAssert(cell.faceModel.asset, @"assetModel in cell should not be nil");
    BOOL cellIsSelected = cell.faceModel.asset.selectedNum != nil;
    if (cellIsSelected) {
        cell.faceModel.asset.selectedNum = nil;
        [self.selectedAssetArray removeObject:cell.faceModel.asset];
        for (NSInteger i = 0; i < self.selectedAssetArray.count; i++) {
            self.selectedAssetArray[i].selectedNum = @(i + 1);
        }
        NSArray<NSIndexPath *> *indexPaths = [self.collectionView indexPathsForVisibleItems];
        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    } else {
        if (self.selectedAssetArray.count >= self.maxAssetsSelectionCount) {
            NSString *toastText = [NSString stringWithFormat:ACCLocalizedString(@"creation_upload_limit",nil), self.maxAssetsSelectionCount];
            [ACCToast() show:toastText];
            return;
        }
        cell.faceModel.asset.selectedNum = @(self.selectedAssetArray.count + 1);
        [self.selectedAssetArray addObject:cell.faceModel.asset];
        [cell doMultiAssetsSelection];
    }
    if (!cellIsSelected && [self.delegate respondsToSelector:@selector(mattingView:didSelectSubItem:)]) {
        [self.delegate mattingView:self didSelectSubItem:cell.faceModel.asset];
    }
    [self p_updateFinishSelectionButton];
}

- (void)p_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.enableMultiAssetsSelection) {
        [self p_collectionView:collectionView multiAssetsSelectionAtIndexPath:indexPath];
    } else {
        [self p_collectionView:collectionView singleAssetSelectionAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(itemShouldBeSelected:completion:)]) {
        [self.delegate itemShouldBeSelected: self.photoCollector.detectedResult[indexPath.item].asset completion:^{
             [self p_collectionView:collectionView didSelectItemAtIndexPath:indexPath];
        }];
    } else {
        [self p_collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

#pragma mark - Actions
- (void)p_finishSelectionButtonClicked:(id)sender
{
    if (self.selectedAssetArray.count < self.minAssetsSelectionCount) {
        return;
    }
    [self.delegate didChooseAssetModelArray:self.selectedAssetArray];
}

- (void)p_updateFinishSelectionButton
{
    if (self.selectedAssetArray.count >= self.minAssetsSelectionCount) {
        self.finishSelectionButton.alpha = 1;
    } else {
        self.finishSelectionButton.alpha = 0.4;
    }
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    acc_dispatch_main_async_safe(^{
        [self resetFaceDetectingStatus];
        [self resetToInitStateCauseByAlbumChange];
        [self.photoCollector reset];
        [self.photoCollector startDetect];
        [self.delegate albumPhotosChanged];
    });
}

- (void)showLoading:(BOOL)showOrHide {
    self.loadingView.hidden = !showOrHide;
}

#pragma mark - Pixaloop

- (void)setShowPixaloopPlusButton:(BOOL)showPixaloopPlusButton
{
    _showPixaloopPlusButton = showPixaloopPlusButton;
    if (_showPixaloopPlusButton) {
        self.plusButton.hidden = NO;
        ACCMasReMaker(self.plusButton, {
            make.left.equalTo(self).offset(10.0f);
            make.centerY.equalTo(self);
            make.width.height.equalTo(@(40.0f));
        });
        ACCMasReMaker(self.collectionView, {
            make.left.equalTo(self.plusButton.mas_right).offset(2.5);
            make.top.bottom.right.equalTo(self);
        });
    } else {
        self.plusButton.hidden = YES;
        ACCMasReMaker(self.collectionView, {
            make.edges.equalTo(self);
        });
    }
}

- (void)onHeaderViewPlusButton:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(didPressPlusButton)]) {
        [self.delegate didPressPlusButton];
    }
}

#pragma mark - AWEAlbumPhotoCollectorObserver

- (void)collectorDidStartDetect:(AWEAlbumPhotoCollector *)collector
{
    AWELogToolDebug2(@"pixaloop",AWELogToolTagEdit|AWELogToolTagAIClip, @"collector<%@> did start detect", collector.identifier);
}

- (void)collector:(AWEAlbumPhotoCollector *)collector detectResultDidChange:(NSDictionary *)change
{
    AWELogToolDebug2(@"pixaloop",AWELogToolTagEdit|AWELogToolTagAIClip,@" collector<%@> did change", collector.identifier);
    [self.collectionView reloadData];
    [self.collectionView setNeedsLayout];
    [self.collectionView layoutIfNeeded];
    [self showLoading:self.photoCollector.detectedResult.count == 0];
}

- (void)collectorDidPauseDetect:(AWEAlbumPhotoCollector *)collector
{
    AWELogToolDebug2(@"pixaloop",AWELogToolTagEdit|AWELogToolTagAIClip,@" collector<%@> did pause detect", collector.identifier);
}

- (void)collectorDidFinishDetect:(AWEAlbumPhotoCollector *)collector
{
    AWELogToolDebug2(@"pixaloop",AWELogToolTagEdit|AWELogToolTagAIClip,@" collector<%@> did finish detect", collector.identifier);
    if (collector.detectedResult.count == 0) {
        [self showLoading:NO];
    }
    if (self.enableMultiAssetsSelection && !ACC_isEmptyArray(self.selectedAssetArray)) {
        // The user may delete photos outside of our app, so we need to update the selected assets array based on currently detected photo assets.
        [self updateSelectedAssetArray:[self.selectedAssetArray copy]];
    }
}

@end
