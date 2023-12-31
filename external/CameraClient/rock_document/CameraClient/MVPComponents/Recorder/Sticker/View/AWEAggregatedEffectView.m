//
//  AWEAggregatedEffectView.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/7/8.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEAggregatedEffectView.h"
#import <CreativeKit/NSArray+ACCAdditions.h>

#import <KVOController/NSObject+FBKVOController.h>
#import "AWEModernStickerCollectionViewCell.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CameraClient/ACCTrackerUtility.h>

@interface AWEAggregatedEffectView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSIndexPath *selectdIndexPath;
@property (nonatomic, copy) NSArray<IESEffectModel *> *storedArray;
@property (nonatomic, copy) NSArray<NSString *> *effectIdArray;
@property (nonatomic, assign) BOOL needLoadingAnimationForSelectedCell;
@property (nonatomic, strong) NSMutableSet *shownCellSet;

@end

@implementation AWEAggregatedEffectView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer3);
        self.layer.cornerRadius = 9;
        _shownCellSet = [NSMutableSet set];
        [self addSubviews];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.width = self.collectionView.contentSize.width;
    return size;
}

#pragma mark - Properties

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(54, 54);
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 16, 0, 16);
        flowLayout.minimumLineSpacing = 10;
        flowLayout.minimumInteritemSpacing = 7.5;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        if (@available(iOS 10.0, *)) {
            _collectionView.prefetchingEnabled = NO;
        }
        
        [_collectionView registerClass:[AWEModernStickerCollectionViewCell class]
            forCellWithReuseIdentifier:[AWEModernStickerCollectionViewCell identifier]];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
    }
    return _collectionView;
}

#pragma mark - Public

- (void)updateSelectEffectWithEffect:(IESEffectModel *)selectedEffect {
    for (int i = 0; i < self.storedArray.count; i++) {
        IESEffectModel *currentEffect = self.storedArray[i];
        if ([currentEffect.effectIdentifier isEqualToString:selectedEffect.effectIdentifier]) {
            NSIndexPath *toSelectedIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
            self.selectdIndexPath = toSelectedIndexPath;
            // click打点
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
            [params setValue:@"click_banner" forKey:@"enter_method"];
            [params setValue:currentEffect.effectIdentifier ?: @"" forKey:@"prop_id"];
            params[@"enter_from"] = @"video_shoot_page";
            params[@"order"] = @(i).stringValue;
            params[@"prop_rec_id"] = ACC_isEmptyString(currentEffect.recId) ? @"0": currentEffect.recId;
            params[@"impr_position"] = @(i + 1).stringValue;
            if ([self.delegate respondsToSelector:@selector(currentPropSelectedFrom)]) {
                params[@"prop_selected_from"] = self.delegate.currentPropSelectedFrom;
            }
            if ([self.delegate respondsToSelector:@selector(localPropId)]) {
                NSString *localPropId = [self.delegate localPropId];
                if (!ACC_isEmptyString(localPropId)) {
                    params[@"from_prop_id"] = localPropId;
                    params[@"is_default_prop"] = [self.effectIdArray containsObject:localPropId] ? @"1" : @"0";
                }
            }
            //==============================================================================
            AVCaptureDevicePosition cameraPostion = self.delegate.aggregatedEffectViewCameraService.cameraControl.currentCameraPosition;
            params[@"camera_direction"] = ACCDevicePositionStringify(cameraPostion);
            //==============================================================================
            if ([self shouldTrackPropEvent]) {
                [ACCTracker() trackEvent:@"prop_click" params:params needStagingFlag:NO];
            }
            break;
        }
    }
}

- (void)updateAggregatedEffectArrayWith:(NSArray<IESEffectModel *> *)aggregatedArray {
    [self.collectionView setContentOffset:CGPointZero animated:NO];
    [self.shownCellSet removeAllObjects];
    // 每次升级data source, 清掉需要loading的flag
    [self cleanLoadingSelectedCell];
    self.storedArray = [aggregatedArray copy];
    self.effectIdArray = [self.storedArray acc_mapObjectsUsingBlock:^NSString * _Nonnull(IESEffectModel * _Nonnull obj, NSUInteger idex) {
        return obj.effectIdentifier;
    }];
    [self.collectionView reloadData];
}

- (IESEffectModel *)nextEffectOfSelectedEffect {
    if (!self.selectdIndexPath || self.selectdIndexPath.item == self.storedArray.count - 1) {
        return nil;
    }
    return self.storedArray[self.selectdIndexPath.item + 1];
}

- (void)setNeedLoadingAnimationForSelectedCell {
    self.needLoadingAnimationForSelectedCell = YES;
}

- (void)cleanLoadingSelectedCell {
    if (self.needLoadingAnimationForSelectedCell) {
        self.needLoadingAnimationForSelectedCell = NO;
        AWEModernStickerCollectionViewCell *selectedCell =
                (AWEModernStickerCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:self.selectdIndexPath];
        if (selectedCell) {
            [selectedCell stopLoadingAnimation];
        }
    }
}

#pragma mark - Protocols
#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.storedArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSString *identifier = [AWEModernStickerCollectionViewCell identifier];
    AWEModernStickerCollectionViewCell *cell =
            (AWEModernStickerCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifier
                                                                                            forIndexPath:indexPath];
    if (self.selectdIndexPath && self.selectdIndexPath.item == indexPath.item) {
        cell.isStickerSelected = YES;
        cell.selectedIndicatorView.alpha = 1.0;
    } else {
        cell.isStickerSelected = NO;
        cell.selectedIndicatorView.alpha = 0.0;
    }
    cell.isInPropPanel = NO;
    [cell configWithEffectModel:self.storedArray[indexPath.item] childEffectModel:nil];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(nonnull UICollectionViewCell *)cell
    forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    AWEModernStickerCollectionViewCell *currentCell = (AWEModernStickerCollectionViewCell *)cell;
    IESEffectModel *effectModel = self.storedArray[indexPath.item];
    if (self.needLoadingAnimationForSelectedCell && [indexPath isEqual:self.selectdIndexPath] && !effectModel.downloaded) {
        [currentCell startLoadingAnimation];
    }
    if (![self.shownCellSet containsObject:currentCell.effect.effectIdentifier]) {
        [self.shownCellSet addObject:currentCell.effect.effectIdentifier];
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
        [params setValue:@"click_banner" forKey:@"enter_method"];
        [params setValue:currentCell.effect.effectIdentifier ?: @"" forKey:@"prop_id"];
        params[@"order"] = @(indexPath.item).stringValue;
        params[@"prop_rec_id"] = ACC_isEmptyString(currentCell.effect.recId) ? @"0": currentCell.effect.recId;
        if ([self.delegate respondsToSelector:@selector(localPropId)]) {
            NSString *localPropId = [self.delegate localPropId];
            if (!ACC_isEmptyString(localPropId)) {
                params[@"from_prop_id"] = localPropId;
            }
        }
        if ([self.delegate respondsToSelector:@selector(musicId)]) {
            NSString *musicId = [self.delegate musicId];
            if (!ACC_isEmptyString(musicId)) {
                params[@"music_id"] = musicId;
            }
        }
        if ([self shouldTrackPropEvent]) {
            [ACCTracker() trackEvent:@"prop_show" params:params needStagingFlag:NO];
        }
    }
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWEModernStickerCollectionViewCell *cell =
            (AWEModernStickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(aggregatedEffectView:shouldBeSelectedWithCell:)]) {
        if (![self.delegate aggregatedEffectView:self shouldBeSelectedWithCell:cell]) {
            return;
        }
    }
    
    if (self.selectdIndexPath && self.selectdIndexPath.item == indexPath.item) {
        // 选择了同一个cell，不做任何处理
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
    [params setValue:@"click_banner" forKey:@"enter_method"];
    [params setValue:cell.effect.effectIdentifier ?: @"" forKey:@"prop_id"];
    params[@"enter_from"] = @"video_shoot_page";
    params[@"order"] = @(indexPath.item).stringValue;
    params[@"prop_rec_id"] = ACC_isEmptyString(cell.effect.recId) ? @"0": cell.effect.recId;
    params[@"impr_position"] = @(indexPath.item + 1).stringValue;
    if ([self.delegate respondsToSelector:@selector(currentPropSelectedFrom)]) {
        params[@"prop_selected_from"] = self.delegate.currentPropSelectedFrom;
    }
    if ([self.delegate respondsToSelector:@selector(localPropId)]) {
        NSString *localPropId = [self.delegate localPropId];
        if (!ACC_isEmptyString(localPropId)) {
            params[@"from_prop_id"] = localPropId;
            params[@"is_default_prop"] = [self.effectIdArray containsObject:localPropId] ? @"1" : @"0";
        }
    }
    //==============================================================================
    AVCaptureDevicePosition cameraPostion = self.delegate.aggregatedEffectViewCameraService.cameraControl.currentCameraPosition;
    params[@"camera_direction"] = ACCDevicePositionStringify(cameraPostion);
    //==============================================================================
    if ([self shouldTrackPropEvent]) {
        [ACCTracker() trackEvent:@"prop_click" params:params needStagingFlag:NO];
    }

    if (!self.selectdIndexPath) {
        [cell makeSelected];
    } else {
        AWEModernStickerCollectionViewCell *selectedCell =
                (AWEModernStickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:self.selectdIndexPath];
        [selectedCell makeUnselected];
        // 清掉之前的loading行为
        self.needLoadingAnimationForSelectedCell = NO;
        [selectedCell stopLoadingAnimation];
        [cell makeSelected];
    }
    self.selectdIndexPath = indexPath;
    [self.delegate aggregatedEffectView:self didSelectEffectCell:cell];
}

#pragma mark - Private
- (BOOL)shouldTrackPropEvent
{
    BOOL shouldTrackPropEvent = YES;
    if ([self.delegate respondsToSelector:@selector(shouldTrackPropEvent:)]) {
        shouldTrackPropEvent = [self.delegate shouldTrackPropEvent:self];
    }
    return shouldTrackPropEvent;
}

- (void)addSubviews {
    [self addSubview:self.collectionView];
    ACCMasMaker(self.collectionView, {
        make.edges.equalTo(self);
    });
    @weakify(self)
    [self.KVOController observe:self.collectionView
                        keyPath:@"contentSize"
                        options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                          block:^(typeof(self) _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
                              @strongify(self);
                              [self invalidateIntrinsicContentSize];
                          }];
}

@end
