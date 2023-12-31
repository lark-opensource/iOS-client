//
//  AWEVoiceChangerSelectView.m
//  Pods
//
//  Created by chengfei xiao on 2019/5/22.
//

#import "AWERepoVoiceChangerModel.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVoiceChangerSelectView.h"
#import "AWEVoiceChangerCell.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>

#import <CreativeKit/ACCMonitorProtocol.h>
#import <CameraClient/AWEEffectPlatformManager.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>

#define kVoiceChangerCollectionViewHeight 90

@interface AWEVoiceChangerSelectView ()<
UICollectionViewDelegate,
UICollectionViewDataSource>

@property (nonatomic, strong) UIView *fadingContainerView;
@property (nonatomic, strong) UILabel *indicatorLabel;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSIndexPath *previousSelectedIndexPath;
@property (nonatomic, strong) NSMutableArray <IESEffectModel *> *effectList;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic,   copy) NSString * recoverVoiceID;
@property (nonatomic, assign) CGFloat contentHeight;
@property (nonatomic, assign) BOOL isSelectedNoneDuetoMultiVoiceEffectSegments;
@property (nonatomic, assign) BOOL isProcessingClearVoiceEffect;
@end


@implementation AWEVoiceChangerSelectView

- (void)dealloc
{
    ACCLog(@"%@ dealloc",self.class);
}

- (instancetype)initWithFrame:(CGRect)frame publishModel:(AWEVideoPublishViewModel *)publishModel
{
    self = [super initWithFrame:frame];
    if (self) {
        _effectList = [NSMutableArray new];
        _publishModel = publishModel;

        [self addSubview:self.indicatorLabel];
        CGFloat rightSpacing = 16;
        CGFloat maxLabelWidth = frame.size.width - rightSpacing - 16;
        CGFloat labelHeight = [self.indicatorLabel sizeThatFits:CGSizeMake(maxLabelWidth, CGFLOAT_MAX)].height + 36;
        
        ACCMasMaker(self.indicatorLabel, {
            make.top.equalTo(@0);
            make.left.equalTo(@16);
            make.height.equalTo(@(labelHeight));
            make.width.equalTo(@(maxLabelWidth));
        });
        self.contentHeight = labelHeight + kVoiceChangerCollectionViewHeight + 16;
        self.fadingContainerView = [[UIView alloc] init];
        //[self.fadingContainerView awe_edgeFading];
        [self addSubview:self.fadingContainerView];
        ACCMasMaker(self.fadingContainerView, {
            make.top.equalTo(@(70.f));
            make.left.equalTo(@0);
            make.right.equalTo(self.mas_right);
            make.height.equalTo(@(kVoiceChangerCollectionViewHeight));
        });
        
        [self.collectionView registerClass:AWEVoiceChangerCell.class forCellWithReuseIdentifier:NSStringFromClass(AWEVoiceChangerCell.class)];
        [self.fadingContainerView addSubview:self.collectionView];
        ACCMasMaker(self.collectionView, {
            make.edges.equalTo(self.fadingContainerView);
        });
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.bounds.size.width, self.contentHeight);
}

- (void)resetSelectedIndex
{
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    self.previousSelectedIndexPath = nil;
    [self p_clearSeletedCellExcept:nil];
    AWEVoiceChangerCell *cell = (AWEVoiceChangerCell *)self.collectionView.visibleCells.firstObject;
    [cell setIsCurrent:YES animated:NO];
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    _selectedIndexPath = selectedIndexPath;
    if (selectedIndexPath.row != NSNotFound && self.isSelectedNoneDuetoMultiVoiceEffectSegments) {
        self.isSelectedNoneDuetoMultiVoiceEffectSegments = NO;
    }
}

- (void)selectNoneItemIfNeeded {
    if (self.publishModel.repoVoiceChanger.voiceEffectSegments.count > 0) {
        self.isSelectedNoneDuetoMultiVoiceEffectSegments = YES;
        self.selectedIndexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:0];
        self.previousSelectedIndexPath = nil;
        [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [self reloadData];
    }
}

- (void)reloadData
{
    [self.collectionView reloadData];
}

- (void)updateWithVoiceEffectList:(NSArray<IESEffectModel *> *)effectList recoverWithVoiceID:( NSString * _Nullable )recoverEffectID
{
    //set data source
    NSMutableArray *arr = [NSMutableArray array];
    //原声
    NSString *title = ACCLocalizedCurrentString(@"none");
    IESEffectModel *orignal = [MTLJSONAdapter modelOfClass:IESEffectModel.class fromJSONDictionary:@{@"name" : title?:@""} error:nil];
    [arr acc_addObject:orignal];
    
    if (effectList.count == 0) {
        if (![self.effectList count]) {
            if ([[AWEEffectPlatformManager sharedManager].localVoiceEffectList count]) {
                arr = [NSMutableArray arrayWithArray:[arr arrayByAddingObjectsFromArray:[AWEEffectPlatformManager sharedManager].localVoiceEffectList]];
            }
        }
    } else {
        // 加下面的是否有effectIdentifier == nil的判断是因为变声的effectList用的是请求数据返回的，不包含“无”，
        // 但是配音的需求如果react或者deut下无配音，需要变声选择无
        NSMutableArray *mArray = [NSMutableArray arrayWithArray:effectList];
        __block BOOL hasNilItem = NO;
        [mArray enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.effectIdentifier) {
                hasNilItem = YES;
                *stop = YES;
            }
        }];
        if (effectList.count && !hasNilItem) {
            arr = [NSMutableArray arrayWithArray:[arr arrayByAddingObjectsFromArray:effectList]];
        } else {
            arr = [effectList mutableCopy];
        }
    }
    self.effectList = arr;

    //recover logic
    IESEffectModel *recoverEffectOfLocal = [[AWEEffectPlatformManager sharedManager] localVoiceEffectWithID:recoverEffectID];
    __block BOOL containsRecoverID = NO;
    __block NSInteger indexPathRow = 0;
    if (recoverEffectID) {
        [self.effectList enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (recoverEffectOfLocal) {
                //effectList里面就是内置的，或者effectList是后台下发的并且其中有音效与内置的一致 && 已下载
                if ([obj.effectIdentifier isEqualToString:recoverEffectID] ||
                    (obj.downloaded && [[AWEEffectPlatformManager sharedManager] equalWithCachedEffect:obj localEffect:recoverEffectOfLocal])) {
                    containsRecoverID = YES;
                    indexPathRow = idx;
                    *stop = YES;
                }
            } else {
                if ([obj.effectIdentifier isEqualToString:recoverEffectID] && obj.downloaded) {
                    containsRecoverID = YES;
                    indexPathRow = idx;
                    *stop = YES;
                }
            }
        }];
        if (containsRecoverID) {
            self.recoverVoiceID = recoverEffectID;
        }
    }
    
    self.selectedIndexPath = [NSIndexPath indexPathForRow:indexPathRow inSection:0];
    self.previousSelectedIndexPath = self.selectedIndexPath;
    
    if (self.isProcessingClearVoiceEffect) {
        self.isProcessingClearVoiceEffect = NO;
        return;
    }
    
    //update ui
    acc_dispatch_main_async_safe(^{
        @weakify(self);
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            @strongify(self);
            if (self.publishModel.repoVoiceChanger.voiceEffectSegments.count > 0) {
                [self selectNoneItemIfNeeded];
            } else if (!self.publishModel.repoVoiceChanger.voiceChangerID){
                [self resetSelectedIndex];
            }
        }];
        [self.collectionView reloadData];
        [CATransaction commit];
    });
}

#pragma mark - setter/getter

- (UICollectionView *)collectionView
{
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        CGRect frame = CGRectMake(10, 52, ACC_SCREEN_WIDTH - 10, kVoiceChangerCollectionViewHeight);
        _collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.contentInset = UIEdgeInsetsMake(0, 12, 0, 12);
        _collectionView.showsHorizontalScrollIndicator = NO;
    }
    return _collectionView;
}

- (UILabel *)indicatorLabel
{
    if (_indicatorLabel == nil) {
        _indicatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 26, ACC_SCREEN_WIDTH - 28 - 20 - 20, 16)];
        _indicatorLabel.font = [ACCFont() acc_systemFontOfSize:13 weight:ACCFontWeightSemibold];
        _indicatorLabel.textColor = ACCColorFromRGBA(255, 255, 255, 1.0f);
        _indicatorLabel.text = ACCLocalizedString(@"creation_edit_voice_effects_will_apply_to_recording_and_original", @"变声功能对原声与配音生效");
        _indicatorLabel.numberOfLines = 0;
    }
    return _indicatorLabel;
}

- (CGFloat)fittingHeight {
    return 10;
}

- (void)setIsPreprocessing:(BOOL)isPreprocessing {
    _isPreprocessing = isPreprocessing;
    if (!_isPreprocessing) {
        [self p_stopLoadingAnimation];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(60, kVoiceChangerCollectionViewHeight);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 8;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 8;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.effectList.count;//原声+音效
}

#pragma mark - UICollectionViewDelegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    AWEVoiceChangerCell *cell = (AWEVoiceChangerCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(AWEVoiceChangerCell.class)
                                                                                                 forIndexPath:indexPath];
    
    if (indexPath.row < [self.effectList count]) {
        IESEffectModel *model = self.effectList[indexPath.row];
        cell.currentEffect = model;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isSelectedNoneDuetoMultiVoiceEffectSegments) {
        @weakify(self);
        @weakify(collectionView);
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:ACCLocalizedCurrentString(@"confirm_discard_voice_effects") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"confirm_discard_voice_effects_discard") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            @strongify(collectionView);
            self.isProcessingClearVoiceEffect = YES;
            ACCBLOCK_INVOKE(self.clearVoiceEffectHandler);
            [self selectNoneItemIfNeeded];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_handleCollectionView:collectionView didSelectItemAtIndexPath:indexPath];
            });
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"confirm_discard_voice_effects_cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
        [ACCAlert() showAlertController:alertController animated:YES];
        return;
    }

    [self p_handleCollectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= [self.effectList count]) {
        return;
    }
    
    AWEVoiceChangerCell *voiceCell = (AWEVoiceChangerCell *)cell;
    if ([indexPath isEqual:self.selectedIndexPath]) {
        if (self.previousSelectedIndexPath != self.selectedIndexPath && self.previousSelectedIndexPath) {
            if (self.selectedIndexPath.row == 0) {
                IESEffectModel *model = [self.effectList acc_objectAtIndex:self.previousSelectedIndexPath.row];
                if (!model.downloaded) {
                    [voiceCell setIsCurrent:NO animated:NO];
                    return;
                }
            }
        }
        [voiceCell setIsCurrent:YES animated:NO];
    } else {
        [voiceCell setIsCurrent:NO animated:NO];
    }
}

#pragma mark - private methods

- (void)p_handleCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.row >= [self.effectList count])) {
        return;
    }
    
    IESEffectModel *tappedModel = self.effectList[indexPath.row];
    ACCBLOCK_INVOKE(self.didTapVoiceEffectHandler, tappedModel, nil);
    if (self.selectedIndexPath == indexPath) {
        AWEVoiceChangerCell *voiceCell = (AWEVoiceChangerCell *)[collectionView cellForItemAtIndexPath:indexPath];
        if (voiceCell.isCurrent) {
            return;
        }
    }
    
    self.previousSelectedIndexPath = indexPath;
    AWEVoiceChangerCell *voiceCell = (AWEVoiceChangerCell *)[collectionView cellForItemAtIndexPath:indexPath];
    IESEffectModel *model = voiceCell.currentEffect;
    [self track_select_voice_effect:model];
    
    if (model.effectIdentifier) {
        if (model.downloadStatus == AWEEffectDownloadStatusDownloading) {
            [self p_clearSeletedCellExcept:voiceCell];
            [voiceCell setIsCurrent:NO animated:NO];
            return;
        }
        if ((!model.downloaded || model.downloadStatus == AWEEffectDownloadStatusUndownloaded) &&
            !([model.effectIdentifier isEqualToString:[AWEEffectPlatformManager sharedManager].localVoiceEffectName_baritone] ||
            [model.effectIdentifier isEqualToString:[AWEEffectPlatformManager sharedManager].localVoiceEffectName_chipmunk])) {//未下载&不是内置
            model.downloadStatus = AWEEffectDownloadStatusDownloading;
            [self p_clearSeletedCellExcept:voiceCell];
            [voiceCell setIsCurrent:NO animated:NO];
            [self p_selectAndDownloadEffectAtIndexPath:indexPath];
        } else {//已下载
            self.selectedIndexPath = indexPath;
            [self p_selectWithCell:voiceCell model:model indexPath:indexPath];
        }
    } else {//原声
        self.selectedIndexPath = indexPath;
        [self p_selectWithCell:voiceCell model:model indexPath:indexPath];
    }
}

- (void)p_selectAndDownloadEffectAtIndexPath:(NSIndexPath *)indexPath
{
    AWEVoiceChangerCell *voiceCell = (AWEVoiceChangerCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    IESEffectModel *model = voiceCell.currentEffect;
    
    [voiceCell showLoadingAnimation:YES];
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    @weakify(self);
    @weakify(voiceCell);
    [EffectPlatform downloadEffect:model downloadQueuePriority:NSOperationQueuePriorityHigh downloadQualityOfService:NSQualityOfServiceUtility progress:^(CGFloat progress) {
        AWELogToolDebug(AWELogToolTagEdit, @"process is %.2f",progress);
    } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
        @strongify(self);
        @strongify(voiceCell);
        
        NSDictionary *extraInfo = @{@"effect_id" : model.effectIdentifier ?: @"",
                                    @"effect_name" : model.effectName ?: @"",
                                    @"download_urls" : [model.fileDownloadURLs componentsJoinedByString:@";"] ?: @""};
        
        if (!error && filePath) {//下载成功
            model.downloadStatus = AWEEffectDownloadStatusDownloaded;
            if (self.previousSelectedIndexPath == indexPath) {
                self.selectedIndexPath = indexPath;
                acc_dispatch_main_async_safe(^{
                    [self p_selectWithCell:voiceCell model:model indexPath:indexPath];
                });
            }
            
            [ACCMonitor() trackService:@"aweme_voice_effect_platform_download_error"
                                     status:0
                                      extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{@"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000)}]];
        } else {//下载失败
            model.downloadStatus = AWEEffectDownloadStatusUndownloaded;
            
            acc_dispatch_main_async_safe(^{
                [ACCToast() show:ACCLocalizedCurrentString(@"load_failed")];
            });
            
            [ACCMonitor() trackService:@"aweme_voice_effect_platform_download_error"
                                     status:1
                                      extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{@"errorCode" : @(error.code),
                                                                                                     @"errorDesc" : error.localizedDescription ?: @""}]];
        }
        
        acc_dispatch_main_async_safe(^{
            [voiceCell showLoadingAnimation:NO];
        });
    }];
}

- (void)p_selectWithCell:(AWEVoiceChangerCell *)voiceCell model:(IESEffectModel *)model indexPath:(NSIndexPath *)indexPath
{
    if (self.recoverVoiceID) {
        self.recoverVoiceID = nil;
    }

    [self p_clearSeletedCellExcept:voiceCell];
    [voiceCell setIsCurrent:YES animated:NO];
    ACCBLOCK_INVOKE(self.didSelectVoiceEffectHandler,model,nil);
}

- (void)p_clearSeletedCellExcept:(AWEVoiceChangerCell *)cell
{
    for (AWEVoiceChangerCell *voiceCell in [self.collectionView visibleCells]) {
        if (voiceCell != cell) {
            [voiceCell setIsCurrent:NO animated:NO];
        }
    }
}

- (void)p_stopLoadingAnimation
{
    for (AWEVoiceChangerCell *voiceCell in [self.collectionView visibleCells]) {
        if (voiceCell.currentEffect.downloaded || voiceCell.currentEffect.downloadStatus == AWEEffectDownloadStatusDownloaded) {
            [voiceCell showLoadingAnimation:NO];
        }
    }
}

#pragma mark - track

- (void)track_select_voice_effect:(IESEffectModel *)effect
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.publishModel.repoTrack.referExtra];
    params[@"enter_from"] = @"video_edit_page";
    NSTimeInterval time = (long long)([[NSDate date] timeIntervalSince1970]*1000);
    params[@"local_time_ms"] = @(time);
    params[@"effect_name"] = effect.effectName;
    params[@"effect_id"] = effect.effectIdentifier;
    
    [ACCTracker() trackEvent:@"select_voice_effect" params:params needStagingFlag:NO];
}

@end
