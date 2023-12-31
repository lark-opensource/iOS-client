//
//  ACCImportMaterialSelectView.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/5.
//

#import "ACCImportMaterialSelectView.h"
#import "ACCImportMaterialSelectCollectionViewCell.h"
#import "ACCBubbleProtocol.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCResponder.h>
#import "CAKAlbumAssetModel+Convertor.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeAlbumKit/CAKAlbumPreviewAndSelectController.h>
#import <EffectPlatformSDK/IESEffectModel.h>

@interface ACCImportMaterialSelectView ()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong, readwrite) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray<ACCImportMaterialSelectCollectionViewCellModel *> *allModels;

@property (nonatomic,   weak) UIView *curBubble;

@property (nonatomic, strong) UIView *seperatorLineView;

@property (nonatomic, assign) NSInteger highlightIndex;

@property (nonatomic, assign) BOOL checkMaterialRepeatSelect;

@end

@implementation ACCImportMaterialSelectView

- (instancetype)initWithFrame:(CGRect)frame withChangeCellColor:(BOOL)shouldChangeCellColor
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _shouldChangeCellColor = shouldChangeCellColor;
        [self setupUI];
    }
    
    return self;
}

- (void)setupUI
{
    self.seperatorLineView.frame = CGRectMake(0, 0, self.bounds.size.width, 0.5);
    [self addSubview:self.seperatorLineView];
    [self addSubview:self.collectionView];
}

- (void)setTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
{
    if (_templateModel != templateModel) {
        _templateModel = templateModel;
        
        self.allModels = [NSMutableArray array];

        [templateModel.extraModel.fragments enumerateObjectsUsingBlock:^(id<ACCCutSameFragmentModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.duration != nil) {
                [self.allModels addObject:({
                    ACCImportMaterialSelectCollectionViewCellModel *cellModel = [[ACCImportMaterialSelectCollectionViewCellModel alloc] init];
                    if (idx == 0) {
                        cellModel.highlight = YES;
                    }
                    cellModel.duration = obj.duration.doubleValue/1000.0;
                    if (self.templateModel.effectModel == nil) {
                        cellModel.shouldShowDuration = YES;
                    } else {
                        cellModel.shouldShowDuration = NO;
                    }
                    cellModel.shouldChangeCellColor = self.shouldChangeCellColor;
                    
                    cellModel;
                })];
            }
        }];
        
        [self reloadSelectView];
    }
}

- (void)setSingleFragmentModel:(id<ACCCutSameFragmentModelProtocol>)singleFragmentModel
{
    if (_singleFragmentModel != singleFragmentModel) {
        _singleFragmentModel = singleFragmentModel;
        
        self.allModels = [NSMutableArray array];
        if (singleFragmentModel.duration != nil) {
            [self.allModels addObject:({
                ACCImportMaterialSelectCollectionViewCellModel *cellModel = [[ACCImportMaterialSelectCollectionViewCellModel alloc] init];
                cellModel.duration = singleFragmentModel.duration.doubleValue;
                cellModel.shouldShowDuration = YES;
                cellModel.shouldChangeCellColor = self.shouldChangeCellColor;
                cellModel;
            })];
        }
        
        [self reloadSelectView];
    }
}

- (BOOL)topVCIsPreviewVC
{
    UIViewController *topVC = [ACCResponder topViewController];
    if ([topVC isKindOfClass:[CAKAlbumPreviewAndSelectController class]]) {
        return YES;
    }
    return NO;
}

#pragma mark - ACCSelectedAssetsViewProtocol
- (void)reloadSelectView
{
    if (self.templateModel || self.singleFragmentModel) {
        NSMutableArray<CAKAlbumAssetModel *> *tmpAssetModelArray = [NSMutableArray arrayWithArray:self.assetModelArray];
        NSMutableArray<ACCImportMaterialSelectCollectionViewCellModel *> *nilAssetModel = [NSMutableArray array];
        
        //check数据源和当前dock栏中已显示的素材
        [self.allModels enumerateObjectsUsingBlock:^(ACCImportMaterialSelectCollectionViewCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSInteger index = [tmpAssetModelArray indexOfObject:obj.assetModel];
            obj.highlight = NO;
            if (index == NSNotFound) {
                obj.assetModel = nil;
            }
            
            if (obj.assetModel) {
                if (self.checkMaterialRepeatSelect) {
                    [tmpAssetModelArray removeObjectAtIndex:index];
                } else {
                    [tmpAssetModelArray removeObject:obj.assetModel];
                }
            } else {
                [nilAssetModel addObject:obj];
            }
        }];
        
        //新增素材按空位顺序添加
        [tmpAssetModelArray enumerateObjectsUsingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (nilAssetModel.count <= idx) {
                *stop = YES;
            } else {
                nilAssetModel[idx].assetModel = obj;
            }
        }];
        
        //更新当前第一个空位的index
        __block NSInteger firstEmptyIndex = NSNotFound;
        [self.allModels enumerateObjectsUsingBlock:^(ACCImportMaterialSelectCollectionViewCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.assetModel == nil) {
                obj.highlight = YES;
                firstEmptyIndex = idx;
                *stop = YES;
            }
        }];
        self.highlightIndex = firstEmptyIndex;
        
        [self.collectionView reloadData];
    }
}

- (BOOL)checkVideoValidForCutSameTemplate:(CAKAlbumAssetModel *)assetModel
{
    NSTimeInterval duration = assetModel.phAsset.duration;
    NSInteger __block curIdx;
    ACCImportMaterialSelectCollectionViewCellModel __block *curCellModel = nil;
    [self.allModels enumerateObjectsUsingBlock:^(ACCImportMaterialSelectCollectionViewCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.assetModel == nil) {
            curIdx = idx;
            curCellModel = obj;
            *stop = YES;
        }
    }];
    
    if (curCellModel &&
        duration < curCellModel.duration) {
        if (self.curBubble) {
            [ACCBubble() removeBubble:self.curBubble];
        }
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:curIdx inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            NSString *hintContent = [NSString stringWithFormat:ACCLocalizedString(@"mv_select_video_toast", @"视频时长不能小于  %.1f 秒"), curCellModel.duration];
            if ([self topVCIsPreviewVC]) {
                [ACCToast() show:hintContent];
            } else {
                self.curBubble =
                [ACCBubble() showBubble:hintContent
                                   forView:[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:curIdx inSection:0]]
                           inContainerView:self
                          anchorAdjustment:CGPointZero
                               inDirection:ACCBubbleDirectionUp
                                   bgStyle:ACCBubbleBGStyleDefault
                             numberOfLines:0
                                completion:nil];
            }
        });
        
        return NO;
    }
    
    return YES;
}

- (NSMutableArray<CAKAlbumAssetModel *> *)currentAssetModelArray
{
    NSMutableArray<CAKAlbumAssetModel *> *result = [[NSMutableArray alloc] init];
    [self.allModels enumerateObjectsUsingBlock:^(ACCImportMaterialSelectCollectionViewCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.assetModel) {
            [result addObject:obj.assetModel];
        }
    }];
    
    return result;
}

- (NSMutableArray<NSNumber *> *)currentNilIndexArray
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [self.allModels enumerateObjectsUsingBlock:^(ACCImportMaterialSelectCollectionViewCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.assetModel == nil) {
            [result addObject:@(idx)];
        }
    }];
    
    return result;
}

- (void)scrollToNextSelectCell
{
    NSIndexPath __block *targetIndexPath;
    [self.allModels enumerateObjectsUsingBlock:^(ACCImportMaterialSelectCollectionViewCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.assetModel == nil) {
            targetIndexPath = [NSIndexPath indexPathForItem:idx inSection:0];
            *stop = YES;
        }
    }];
    
    if (targetIndexPath == nil) {
        targetIndexPath = [NSIndexPath indexPathForItem:self.allModels.count-1 inSection:0];
    }
    [self.collectionView scrollToItemAtIndexPath:targetIndexPath
                                atScrollPosition:UICollectionViewScrollPositionRight
                                        animated:YES];
}

- (void)updateSelectViewOrderWithNilArray:(NSMutableArray<NSNumber *> *)nilArray
{
    //根据空位位置，更新dock栏
    __block NSInteger currentAssetIndex = 0;
    @weakify(self);
    [self.allModels enumerateObjectsUsingBlock:^(ACCImportMaterialSelectCollectionViewCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        obj.highlight = NO;
        if ([nilArray containsObject:@(idx)]) {
            obj.assetModel = nil;
        } else {
            obj.assetModel = [self.assetModelArray acc_objectAtIndex:currentAssetIndex];
            currentAssetIndex++;
        }
    }];
    
    [self.allModels enumerateObjectsUsingBlock:^(ACCImportMaterialSelectCollectionViewCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.assetModel == nil) {
            obj.highlight = YES;
            *stop = YES;
        }
    }];
    
    [self.collectionView reloadData];
}

- (NSInteger)currentSelectViewHighlightIndex
{
    return self.highlightIndex;
}

- (void)updateCheckMaterialRepeatSelect:(BOOL)checkRepeatSelect
{
    self.checkMaterialRepeatSelect = checkRepeatSelect;
}

#pragma mark - Lazy load properties
- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 12;
        layout.sectionInset = UIEdgeInsetsMake(0, 12, 0.0, 12);
        layout.itemSize = CGSizeMake(64, 64);
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.alwaysBounceVertical = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[ACCImportMaterialSelectCollectionViewCell class]
            forCellWithReuseIdentifier:@"Cell"];
    }
    
    return _collectionView;
}

- (UIView *)seperatorLineView
{
    if (!_seperatorLineView) {
        _seperatorLineView = [[UIView alloc] init];
        _seperatorLineView.backgroundColor = ACCResourceColor(ACCColorLineReverse2);
        _seperatorLineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    
    return _seperatorLineView;
}

#pragma mark - UICollectionViewDataSource
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCImportMaterialSelectCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    [cell bindModel:self.allModels[indexPath.item]];
    cell.currentIndexPath = indexPath;
    
    @weakify(self);
    cell.deleteAction = ^(ACCImportMaterialSelectCollectionViewCell * _Nonnull cell) {
        @strongify(self);
        CAKAlbumAssetModel *assetModel = cell.cellModel.assetModel;
        if (self.checkMaterialRepeatSelect) {
            __block NSInteger tempIndex = cell.currentIndexPath.item;
            [self.allModels enumerateObjectsUsingBlock:^(ACCImportMaterialSelectCollectionViewCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (idx < cell.currentIndexPath.row && obj.assetModel == nil) {
                    tempIndex--;
                }
            }];
            assetModel.cellIndexPath = [NSIndexPath indexPathForRow:tempIndex inSection:cell.currentIndexPath.section];
        }

        cell.cellModel.assetModel = nil;
        
        BOOL __block highlightFlag = YES;
        [self.allModels enumerateObjectsUsingBlock:^(ACCImportMaterialSelectCollectionViewCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.assetModel == nil) {
                obj.highlight = highlightFlag;
                highlightFlag = NO;
            } else {
                obj.highlight = NO;
            }
        }];
        ACCBLOCK_INVOKE(self.deleteAssetModelBlock, assetModel);
        if (!self.checkMaterialRepeatSelect) {
            [self.assetModelArray removeObject:assetModel];
        }
        [self.collectionView reloadData];
    };
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.allModels.count;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.touchAssetModelBlock) {
        if (self.checkMaterialRepeatSelect) {
            __block NSInteger tempIndex = indexPath.item;
            [self.allModels enumerateObjectsUsingBlock:^(ACCImportMaterialSelectCollectionViewCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (idx < indexPath.item && obj.assetModel == nil) {
                    tempIndex--;
                }
            }];
            self.allModels[indexPath.item].assetModel.cellIndexPath = [NSIndexPath indexPathForRow:tempIndex inSection:indexPath.section];
        }
        self.touchAssetModelBlock(self.allModels[indexPath.item].assetModel);
    }
}

@end
