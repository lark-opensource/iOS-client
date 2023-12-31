//
//  ACCModernPOIStickerSwitchView.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/9/23.
//

#import "ACCModernPOIStickerSwitchView.h"
#import "ACCPOIStickerModel.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCModernPOIStickerView.h"
#import "ACCStickerPreviewCollectionViewCell.h"

#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <EffectPlatformSDK/IESEffectModel.h>

CGFloat const kACCModernPOIStickerSwitchViewBottomHeight = 162.f;
CGFloat const kACCModernPOIStickerShowOrDismissAniDuration = 0.3;

@interface ACCModernPOIStickerSwitchView()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, weak) ACCModernPOIStickerView *stickerView;

@property (nonatomic, strong) AWEInteractionModernPOIStickerInfoModel *poiStyleInfo;

@property (nonatomic, strong) NSMutableDictionary *downloadingDict;

@property (nonatomic, strong) UIView *gesView; // Receive tap to dismiss

@property (nonatomic, strong) UIView *contentView; // Bottom content

@property (nonatomic, strong) UILabel *locationLabel;

@property (nonatomic, strong) UICollectionView *styleIconsView;

@end

@implementation ACCModernPOIStickerSwitchView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        _downloadingDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setupUI
{
    self.gesView = [[UIView alloc] init];
    self.gesView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.34];
    [self.gesView acc_addSingleTapRecognizerWithTarget:self action:@selector(clickToDismiss)];
    [self addSubview:self.gesView];
    ACCMasMaker(self.gesView, {
        make.edges.equalTo(self);
    });
    
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor blackColor];
    [self addSubview:self.contentView];
    ACCMasMaker(self.contentView, {
        make.left.equalTo(self);
        make.right.equalTo(self);
        make.bottom.equalTo(self);
        make.height.equalTo(@(kACCModernPOIStickerSwitchViewBottomHeight + ACC_IPHONE_X_BOTTOM_OFFSET));
    });
    
    // Right change location button
    UIButton *changeLocationBtn = [[UIButton alloc] init];
    changeLocationBtn.layer.cornerRadius = 4.f;
    changeLocationBtn.layer.masksToBounds = YES;
    changeLocationBtn.titleLabel.font = [UIFont systemFontOfSize:13.f];
    changeLocationBtn.titleEdgeInsets = UIEdgeInsetsMake(5.f, 8.f, 5.f, 8.f);
    changeLocationBtn.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
    [changeLocationBtn setTitle:ACCLocalizedString(@"locationsticker_changelocation",@"Change location") forState:UIControlStateNormal];
    [changeLocationBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [changeLocationBtn setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [changeLocationBtn setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [changeLocationBtn acc_addSingleTapRecognizerWithTarget:self action:@selector(clickToSwitchPOI)];
    [self.contentView addSubview:changeLocationBtn];
    ACCMasMaker(changeLocationBtn, {
        make.top.equalTo(@12);
        make.right.equalTo(@-15);
        make.height.equalTo(@28);
    });

    // Left change location icon
    UIImageView *locationIconView = [[UIImageView alloc] init];
    locationIconView.image = ACCResourceImage(@"icon_edit_publish_location");
    [locationIconView acc_addSingleTapRecognizerWithTarget:self action:@selector(clickToSwitchPOI)];
    [self.contentView addSubview:locationIconView];
    ACCMasMaker(locationIconView, {
        make.centerY.equalTo(changeLocationBtn);
        make.left.equalTo(@15);
        make.width.equalTo(@12);
        make.height.equalTo(@12);
    });
    
    // Center location detail label
    UILabel *locationLabel = [[UILabel alloc] init];
    locationLabel.textColor = [UIColor whiteColor];
    locationLabel.font = [UIFont systemFontOfSize:13.f];
    locationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    locationLabel.userInteractionEnabled = YES;
    [locationLabel acc_addSingleTapRecognizerWithTarget:self action:@selector(clickToSwitchPOI)];
    self.locationLabel = locationLabel;
    [self.contentView addSubview:locationLabel];
    ACCMasMaker(locationLabel, {
        make.left.equalTo(locationIconView.mas_right).offset(5);
        make.right.equalTo(changeLocationBtn.mas_left).offset(-5);
        make.centerY.equalTo(changeLocationBtn);
        make.height.equalTo(@28);
    });
    
    // Content scrollview
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 16.f;
    layout.itemSize = CGSizeMake(52.f,75.f);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *styleIconsView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    styleIconsView.backgroundColor = [UIColor clearColor];
    styleIconsView.contentInset = UIEdgeInsetsMake(0.f, 12.f, 0.f, 0.f);
    styleIconsView.showsHorizontalScrollIndicator = NO;
    styleIconsView.delegate = self;
    styleIconsView.dataSource = self;
    self.styleIconsView = styleIconsView;
    [self.contentView addSubview:styleIconsView];
    ACCMasMaker(self.styleIconsView, {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.top.equalTo(@64);
        make.height.equalTo(@75);
    });

    [styleIconsView registerClass:[ACCStickerPreviewCollectionViewCell class] forCellWithReuseIdentifier:[ACCStickerPreviewCollectionViewCell identifier]];
    [self layoutIfNeeded];
}

- (void)showSelectViewForSticker:(ACCModernPOIStickerView *)stickerView
{
    self.stickerView = stickerView;
    self.poiStyleInfo = stickerView.model.styleInfos;
    
    self.locationLabel.text = stickerView.model.poiName;

    self.contentView.acc_top = self.acc_height;
    [UIView animateWithDuration:kACCModernPOIStickerShowOrDismissAniDuration animations:^{
        self.contentView.acc_bottom = self.acc_height;
    } completion:^(BOOL finished) {
        [self reloadIcons];
    }];
}

- (void)dismissSelectView:(void(^)())completionBlock
{
    [UIView animateWithDuration:kACCModernPOIStickerShowOrDismissAniDuration animations:^{
        self.contentView.acc_top = self.acc_height;
    } completion:^(BOOL finished) {
        ACCBLOCK_INVOKE(completionBlock);
    }];
}

- (void)reloadIcons
{
    [self.styleIconsView reloadData];
    if (self.poiStyleInfo.currentEffectIndex < self.poiStyleInfo.effects.count) {
        // Scroll to last position
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.poiStyleInfo.currentEffectIndex inSection:0];
        [self.styleIconsView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

#pragma mark - Delegate & Datasource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.poiStyleInfo.effects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCStickerPreviewCollectionViewCell *poiStyleCell = [self.styleIconsView dequeueReusableCellWithReuseIdentifier:[ACCStickerPreviewCollectionViewCell identifier] forIndexPath:indexPath];
    IESEffectModel *effect = [self.poiStyleInfo.effects acc_objectAtIndex:indexPath.row];
    [poiStyleCell configCellWithEffect:effect];
    [poiStyleCell showCurrentTag:(indexPath.row == self.poiStyleInfo.currentEffectIndex)];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:effect.filePath]) {
        [poiStyleCell updateDownloadStatus:AWEEffectDownloadStatusDownloaded];
    } else {
        BOOL downloading = [[self.downloadingDict objectForKey:@(indexPath.row).stringValue] boolValue];
        [poiStyleCell updateDownloadStatus:downloading ? AWEEffectDownloadStatusDownloading : AWEEffectDownloadStatusUndownloaded];
    }
    return poiStyleCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.poiStyleInfo.currentEffectIndex || [[self.downloadingDict objectForKey:@(indexPath.row).stringValue] boolValue]) {
        return;
    }
    ACCStickerPreviewCollectionViewCell *poiStyleCell = (ACCStickerPreviewCollectionViewCell *)[self.styleIconsView cellForItemAtIndexPath:indexPath];
    [poiStyleCell updateDownloadStatus:AWEEffectDownloadStatusDownloading];
    [self.downloadingDict setObject:@YES forKey:@(indexPath.row).stringValue];
    if ([self.delegate respondsToSelector:@selector(editStickerViewStyle:didSelectIndex:completionBlock:)]) {
        @weakify(self);
        [self.delegate editStickerViewStyle:self.stickerView didSelectIndex:indexPath.row completionBlock:^(BOOL success){
            @strongify(self);
            [self.downloadingDict removeObjectForKey:@(indexPath.row).stringValue];
            [self reloadIcons];
        }];
    }
}

#pragma mark - Event Handle
- (void)clickToSwitchPOI
{
    if ([self.delegate respondsToSelector:@selector(selectPOIForEditStickerViewStyle)]) {
        [self.delegate selectPOIForEditStickerViewStyle];
    }
}

- (void)clickToDismiss
{
    if ([self.delegate respondsToSelector:@selector(dismissEditStickerViewStyle:)]) {
        [self.delegate dismissEditStickerViewStyle:NO];
    }
}

@end
