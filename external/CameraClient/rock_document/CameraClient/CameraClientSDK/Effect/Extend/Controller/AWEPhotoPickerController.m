//
//  AWEPhotoPickerController.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/13.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>

#import <CameraClient/AWEPhotoPickerCollectionViewCell.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <Masonry/View+MASAdditions.h>
#import <KVOController/KVOController.h>

#import <CreationKitInfra/ACCLogProtocol.h>
#import "AWEAutoresizingCollectionView.h"
#import "AWEPhotoPickerController.h"
#import <CreationKitInfra/ACCRACWrapper.h>

@interface AWEPhotoPickerController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong, readwrite) AWEPhotoPickerModel *photoPickerModel;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIButton *plusButton;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, assign) BOOL multiSelectionEnabled;

@end

@implementation AWEPhotoPickerController

- (void)dealloc {
    AWELogToolDebug(AWELogToolTagNone, @"%s", __func__);
}

- (instancetype)initWithResourceType:(AWEGetResourceType)resourceType
                enableMultiSelection:(BOOL)enableMultiSelection
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        _multiSelectionEnabled = enableMultiSelection;
        @weakify(self);
        _photoPickerModel = [[AWEPhotoPickerModel alloc] initWithResourceType:resourceType];
        _photoPickerModel.didUpdatedBlock = ^{
            @strongify(self);
            [self reloadData];
            [self scrollSelectedToCenterAnimated:NO];
        };
        _photoPickerModel.didResetSelectedAssetBlock = ^{
            @strongify(self);
            // Call delegate
            if ([self.delegate respondsToSelector:@selector(photoPickerController:didSelectAsset:atIndex:)]) {
                [self.delegate photoPickerController:self didSelectAsset:nil atIndex:NSNotFound];
            }
        };
        [self.KVOController observe:_photoPickerModel
                            keyPath:FBKVOKeyPath(_photoPickerModel.selectedAssetModelArray)
                            options:NSKeyValueObservingOptionNew
                              block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
            @strongify(self);
            [self reloadData];
            if (self.multiSelectionEnabled) {
                [self updateMultiSelectionFinishButtonStatus];
            }
            [self scrollSelectedToCenterAnimated:YES];
        }];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 面板上方显示聚合道具视图
    self.view.backgroundColor = [UIColor clearColor];

    // asset content view
    self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer3);
    self.contentView.layer.cornerRadius = 9;
    [self.view addSubview:self.contentView];
    ACCMasMaker(self.contentView, {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@(65));
    })
    
    // Plus Button
    self.plusButton = [[UIButton alloc] init];
    self.plusButton.isAccessibilityElement = YES;
    self.plusButton.accessibilityTraits = UIAccessibilityTraitNone;
    self.plusButton.accessibilityLabel = @"进入相册选择页";
    [self.plusButton setImage:ACCResourceImage(@"pixaloop_icon_upload") forState:UIControlStateNormal];
    [self.plusButton addTarget:self action:@selector(onPlusButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.plusButton];
    ACCMasReMaker(self.plusButton, {
        make.left.equalTo(self.contentView).offset(10);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@(40.0f));
    });

    if (self.multiSelectionEnabled) {
        [self loadFinishSelectionButton];
    }

    // Collection View
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(48, 48);
    flowLayout.minimumInteritemSpacing = 8;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 7.5, 0, 7.5);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.collectionView = [[AWEAutoresizingCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    if (@available(iOS 10.0, *)) {
        self.collectionView.prefetchingEnabled = NO;
    }
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    if (self.multiSelectionEnabled) {
        [self.collectionView registerClass:[AWEPhotoPickerCollectionViewMultiAssetsCell class]
                forCellWithReuseIdentifier:[AWEPhotoPickerCollectionViewCell identifier]];
    } else {
        [self.collectionView registerClass:[AWEPhotoPickerCollectionViewCell class] forCellWithReuseIdentifier:[AWEPhotoPickerCollectionViewCell identifier]];
    }
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.contentView addSubview:self.collectionView];
    ACCMasReMaker(self.collectionView, {
        make.left.equalTo(self.plusButton.mas_right).offset(2.5);
        make.top.bottom.right.equalTo(self.contentView);
    });

    // Load model
    [self.photoPickerModel load];
    [self updateMultiSelectionFinishButtonStatus];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self scrollSelectedToCenterAnimated:YES];
}

- (void)reloadData {
    [self.collectionView reloadData];
    [self.collectionView setNeedsLayout];
    [self.collectionView layoutIfNeeded];
}

- (void)scrollSelectedToCenterAnimated:(BOOL)animated
{
    // scroll collection view only for single-asset selection
    if (self.multiSelectionEnabled) {
        return;
    }
    if (self.photoPickerModel.selectedAssetIndexArray.count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.photoPickerModel.selectedAssetIndexArray.lastObject integerValue] inSection:0];
        if (indexPath.section < self.collectionView.numberOfSections && indexPath.item < [self.collectionView numberOfItemsInSection:indexPath.section]) {
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
        }
    }
}

#pragma mark - UI Events

- (void)onPlusButtonPressed:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(photoPickerControllerDidSelectPlusButton:)]) {
        [self.delegate photoPickerControllerDidSelectPlusButton:self];
    }
}

- (void)onMultiSelectionFinishButtonClicked:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(photoPickerController:didClickMultiSelectionFinishButton:)]) {
        [self.delegate photoPickerController:self didClickMultiSelectionFinishButton:button];
    }
}

#pragma mark - UICollectionViewDelegate & UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photoPickerModel.assetModels.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AWEAssetModel *assetModel = self.photoPickerModel.assetModels[indexPath.item];
    AWEPhotoPickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWEPhotoPickerCollectionViewCell identifier] forIndexPath:indexPath];
    cell.assetModel = assetModel;
    cell.assetSelected = [self.photoPickerModel.selectedAssetIndexArray containsObject:@(indexPath.item)];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AWEAssetModel *assetModel = self.photoPickerModel.assetModels[indexPath.item];
    // Call delegate
    if ([self.delegate respondsToSelector:@selector(photoPickerController:didSelectAsset:atIndex:)]) {
        [self.delegate photoPickerController:self didSelectAsset:assetModel atIndex:indexPath.item];
    }
}

#pragma mark - Utils
- (void)updateMultiSelectionFinishButtonStatus
{
    BOOL shouldEnable = self.photoPickerModel.selectedAssetIndexArray.count >= self.minSelectionCount;
    self.circularFinishButton.alpha = shouldEnable ? 1 : 0.4;
    self.circularFinishButton.enabled = shouldEnable;
    self.rectangleFinishButton.alpha = shouldEnable ? 1 : 0.4;
    self.rectangleFinishButton.enabled = shouldEnable;
}

- (void)updateViewForExposedPanelLayoutManager:(BOOL)exposed
{
    if (!self.multiSelectionEnabled) {
        return;
    }
    if (exposed) {
        ACCMasUpdate(self.collectionView, {
            make.right.equalTo(self.contentView).offset(-48);
        })
    } else {
        ACCMasUpdate(self.collectionView, {
            make.right.equalTo(self.contentView);
        })
    }
}

- (void)loadFinishSelectionButton
{
    self.circularFinishButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.circularFinishButton setImage:ACCResourceImage(@"iconCheck") forState:UIControlStateNormal];
    [self.circularFinishButton setImage:ACCResourceImage(@"iconCheck") forState:UIControlStateHighlighted];
    self.circularFinishButton.layer.cornerRadius = 16;
    self.circularFinishButton.backgroundColor = ACCResourceColor(ACCColorPrimary);
    self.circularFinishButton.layer.masksToBounds = YES;
    [self.circularFinishButton addTarget:self action:@selector(onMultiSelectionFinishButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

    self.rectangleFinishButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.rectangleFinishButton setTitle:@"完成" forState:UIControlStateNormal];
    self.rectangleFinishButton.backgroundColor = ACCResourceColor(ACCColorPrimary);
    self.rectangleFinishButton.titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightRegular];
    self.rectangleFinishButton.layer.cornerRadius = 2.0;
    [self.rectangleFinishButton addTarget:self action:@selector(onMultiSelectionFinishButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Getters


@end
