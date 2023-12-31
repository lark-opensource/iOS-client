//
//  ACCImageAlbumCropControlView.m
//  Indexer
//
//  Created by admin on 2021/11/11.
//

#import "ACCImageAlbumCropControlView.h"
#import "ACCImageAlbumCropViewModel.h"

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

static const CGFloat kCropRatioCellWidth = 68.0;
static const CGFloat kCropRatioCellHeight = 78.0;
static const CGFloat kCropRatioCellCircleViewWidth = 52.0;

static NSString * const kCropRatioDataSourceKeyForTitle = @"kCropRatioDataSourceKeyForTitle";
static NSString * const kCropRatioDataSourceKeyForRatio = @"kCropRatioDataSourceKeyForRatio";

@interface ACCImageAlbumCropRatioCellModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) ACCImageAlbumItemCropRatio cropRatio;

@end

@implementation ACCImageAlbumCropRatioCellModel

@end


@interface ACCImageAlbumCropRatioCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *circleImageView;

@end

@implementation ACCImageAlbumCropRatioCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupView];
        [self p_setupLayout];
        
        self.isAccessibilityElement = YES;
    }
    return self;
}

+ (NSString *)cellIdentifier
{
    return NSStringFromClass(self);
}

- (void)loadData:(ACCImageAlbumCropRatioCellModel *)cellModel isSelected:(BOOL)isSelected
{
    self.titleLabel.text = cellModel.title;
    self.accessibilityLabel = cellModel.title;
    
    if (isSelected) {
        self.circleImageView.layer.borderColor = ACCResourceColor(ACCUIColorConstPrimary).CGColor;
        self.circleImageView.layer.borderWidth = 2.0;
        
        ACCMasUpdate(self.circleImageView, {
            make.top.equalTo(self).offset(0.0);
            make.size.mas_equalTo(CGSizeMake(kCropRatioCellCircleViewWidth + 2.0, kCropRatioCellCircleViewWidth + 2.0));
        });
    } else {
        self.circleImageView.layer.borderColor = UIColor.clearColor.CGColor;
        self.circleImageView.layer.borderWidth = 0.0;
        
        ACCMasUpdate(self.circleImageView, {
            make.top.equalTo(self).offset(2.0);
            make.size.mas_equalTo(CGSizeMake(kCropRatioCellCircleViewWidth, kCropRatioCellCircleViewWidth));
        });
    }
    
    switch (cellModel.cropRatio) {
        case ACCImageAlbumItemCropRatioOriginal:
            self.circleImageView.image = ACCResourceImage(@"image_album_crop_original");
            break;
            
        case ACCImageAlbumItemCropRatio9_16: {
            self.circleImageView.image = ACCResourceImage(@"image_album_crop_9_16");
            self.accessibilityLabel = @"9比16";  //默认会读为“9 16”，应该是“9比16”，所以要手动修改
            break;
        }
            
        case ACCImageAlbumItemCropRatio3_4:
            self.circleImageView.image = ACCResourceImage(@"image_album_crop_3_4");
            break;
            
        case ACCImageAlbumItemCropRatio1_1:
            self.circleImageView.image = ACCResourceImage(@"image_album_crop_1_1");
            break;
            
        case ACCImageAlbumItemCropRatio4_3:
            self.circleImageView.image = ACCResourceImage(@"image_album_crop_4_3");
            break;
            
        case ACCImageAlbumItemCropRatio16_9:
            self.circleImageView.image = ACCResourceImage(@"image_album_crop_16_9");
            self.accessibilityLabel = @"16比9";  //默认阅读会有问题，所以要手动修改
            break;
            
        default:
            self.circleImageView.image = ACCResourceImage(@"image_album_crop_original");
            break;
    }
}

#pragma mark - Private

- (void)p_setupView
{
    [self.contentView addSubview:self.circleImageView];
    [self.contentView addSubview:self.titleLabel];
}

- (void)p_setupLayout
{
    ACCMasMaker(self.circleImageView, {
        make.top.equalTo(self).offset(2.0);
        make.centerX.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(kCropRatioCellCircleViewWidth, kCropRatioCellCircleViewWidth));
    });
    
    ACCMasMaker(self.titleLabel, {
        make.leading.trailing.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(15);
    });
}

#pragma mark - Getter

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = ({
            UILabel *label = [UILabel.alloc init];
            label.textColor = ACCResourceColor(ACCColorConstTextInverse);
            label.font = [ACCFont() systemFontOfSize:11.f];
            label.textAlignment = NSTextAlignmentCenter;
            label;
        });
    }
    return _titleLabel;
}

- (UIImageView *)circleImageView
{
    if (!_circleImageView) {
        _circleImageView = ({
            UIImageView *imageView = [UIImageView.alloc init];
            imageView.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
            imageView.layer.cornerRadius = kCropRatioCellCircleViewWidth / 2.0;
            imageView.contentMode = UIViewContentModeCenter;
            imageView;
        });
    }
    return _circleImageView;
}

@end

@interface ACCImageAlbumCropControlView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UICollectionView *ratioCollectionView;
@property (nonatomic, strong) NSArray *dataSource;

@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) ACCImageAlbumItemCropInfo *cropInfo;

@end


@implementation ACCImageAlbumCropControlView

- (instancetype)initWithData:(ACCImageAlbumItemCropInfo *)cropInfo
{
    CGRect rect = CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACCImageAlbumCropControlViewHeight);
    self = [super initWithFrame:rect];
    if (self) {
        _selectedIndex = cropInfo.cropRatio;
        if (cropInfo.cropRatio >= self.dataSource.count) {
            _selectedIndex = 0;
            NSAssert(NO, @"Wrong image album crop ratio");
        }
        _cropInfo = cropInfo;
        
        [self p_setupView];
        [self p_setupLayout];
        
        if (cropInfo.cropRatio > ACCImageAlbumItemCropRatio4_3) {
            [self.ratioCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_selectedIndex inSection:0]
                                             atScrollPosition:UICollectionViewScrollPositionLeft
                                                     animated:NO];
        }
    }
    return self;
}

#pragma mark - Action

- (void)handleCloseAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(closeCrop)]) {
        [self.delegate closeCrop];
    }
}

- (void)handleConfirmAction:(id)sender
{
    NSDictionary *dataDict = [self.dataSource acc_objectAtIndex:self.selectedIndex];
    ACCImageAlbumItemCropRatio ratio = (ACCImageAlbumItemCropRatio)[dataDict acc_unsignedIntegerValueForKey:kCropRatioDataSourceKeyForRatio];
    if ([self.delegate respondsToSelector:@selector(confirmCropRatio:)]) {
        [self.delegate confirmCropRatio:ratio];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCImageAlbumCropRatioCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[ACCImageAlbumCropRatioCell cellIdentifier]
                                                                                 forIndexPath:indexPath];
    NSDictionary *dataDict = [self.dataSource acc_objectAtIndex:indexPath.row];
    ACCImageAlbumCropRatioCellModel *cellModel = [self p_modelFromDictionay:dataDict];
    [cell loadData:cellModel isSelected:self.selectedIndex == indexPath.row];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selectedIndex == indexPath.row) {
        return;
    }
    self.selectedIndex = indexPath.row;
    
    NSDictionary *dataDict = [self.dataSource acc_objectAtIndex:indexPath.row];
    ACCImageAlbumItemCropRatio ratio = (ACCImageAlbumItemCropRatio)[dataDict acc_unsignedIntegerValueForKey:kCropRatioDataSourceKeyForRatio];
    if ([self.delegate respondsToSelector:@selector(selectCropRatio:)]) {
        [self.delegate selectCropRatio:ratio];
    }
    
    [collectionView reloadData];
}

#pragma mark - Private

- (ACCImageAlbumCropRatioCellModel *)p_modelFromDictionay:(NSDictionary *)dict
{
    ACCImageAlbumCropRatioCellModel *cellModel = [ACCImageAlbumCropRatioCellModel.alloc init];
    cellModel.title = [dict acc_stringValueForKey:kCropRatioDataSourceKeyForTitle];
    cellModel.cropRatio = [dict acc_integerValueForKey:kCropRatioDataSourceKeyForRatio];
    return cellModel;
}

- (void)p_setupView
{
    self.backgroundColor = ACCResourceColor(ACCColorBGInverse4);
    
    [self addSubview:self.closeButton];
    [self addSubview:self.confirmButton];
    [self addSubview:self.titleLabel];
    [self addSubview:self.ratioCollectionView];
}

- (void)p_setupLayout
{
    CGFloat leftRightMargin = 16.0;
    ACCMasMaker(self.closeButton, {
        make.size.mas_equalTo(CGSizeMake(24.0, 24.0));
        make.leading.equalTo(self).mas_offset(leftRightMargin);
        make.top.equalTo(self).mas_offset(14.0);
    });
    
    ACCMasMaker(self.confirmButton, {
        make.size.equalTo(self.closeButton);
        make.trailing.equalTo(self).mas_offset(-leftRightMargin);
        make.centerY.equalTo(self.closeButton);
    });
    
    ACCMasMaker(self.titleLabel, {
        make.leading.equalTo(self.closeButton.mas_trailing);
        make.trailing.equalTo(self.confirmButton.mas_leading);
        make.centerY.equalTo(self.closeButton);
        make.height.mas_equalTo(30.0);
    });
    
    ACCMasMaker(self.ratioCollectionView, {
        make.leading.trailing.equalTo(self);
        make.top.equalTo(self).offset(72.0);
        make.height.mas_equalTo(kCropRatioCellHeight);
    });
}

#pragma mark - Getter

- (NSArray *)dataSource
{
    return @[@{kCropRatioDataSourceKeyForTitle: @"原始", kCropRatioDataSourceKeyForRatio: @(ACCImageAlbumItemCropRatioOriginal)},
             @{kCropRatioDataSourceKeyForTitle: @"9:16", kCropRatioDataSourceKeyForRatio: @(ACCImageAlbumItemCropRatio9_16)},
             @{kCropRatioDataSourceKeyForTitle: @"3:4", kCropRatioDataSourceKeyForRatio: @(ACCImageAlbumItemCropRatio3_4)},
             @{kCropRatioDataSourceKeyForTitle: @"1:1", kCropRatioDataSourceKeyForRatio: @(ACCImageAlbumItemCropRatio1_1)},
             @{kCropRatioDataSourceKeyForTitle: @"4:3", kCropRatioDataSourceKeyForRatio: @(ACCImageAlbumItemCropRatio4_3)},
             @{kCropRatioDataSourceKeyForTitle: @"16:9", kCropRatioDataSourceKeyForRatio: @(ACCImageAlbumItemCropRatio16_9)}];
}

- (UIButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = ({
            UIButton *button = [UIButton.alloc init];
            button.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-16.f, -16.f, -16.f, -16.f);
            button.accessibilityLabel = @"取消";
            [button setImage:ACCResourceImage(@"ic_toast_close") forState:UIControlStateNormal];
            [button addTarget:self action:@selector(handleCloseAction:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _closeButton;
}

- (UIButton *)confirmButton
{
    if (!_confirmButton) {
        _confirmButton = ({
            UIButton *button = [UIButton.alloc init];
            button.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-16.f, -16.f, -16.f, -16.f);
            button.accessibilityLabel = @"确认";
            [button setImage:ACCResourceImage(@"icon_edit_bar_done") forState:UIControlStateNormal];
            [button addTarget:self action:@selector(handleConfirmAction:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _confirmButton;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = ({
            UILabel *label = [UILabel.alloc init];
            label.text = [ACCImageAlbumCropViewModel cropTitle];
            label.textColor = ACCResourceColor(ACCColorConstTextInverse);
            label.font = [ACCFont() systemFontOfSize:15.f];
            label.textAlignment = NSTextAlignmentCenter;
            label;
        });
    }
    return _titleLabel;
}

- (UICollectionView *)ratioCollectionView
{
    if (!_ratioCollectionView) {
        _ratioCollectionView = ({
            UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
            flowLayout.itemSize = CGSizeMake(kCropRatioCellWidth, kCropRatioCellHeight);
            flowLayout.minimumLineSpacing = 0;
            flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            
            CGRect collectionViewBounds = CGRectMake(0, 0, ACC_SCREEN_WIDTH, kCropRatioCellHeight);
            UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:collectionViewBounds collectionViewLayout:flowLayout];
            collectionView.delegate = self;
            collectionView.dataSource = self;
            collectionView.backgroundColor = [UIColor clearColor];
            collectionView.alwaysBounceVertical = NO;
            collectionView.showsHorizontalScrollIndicator = NO;
            collectionView.contentInset = UIEdgeInsetsMake(0, 8, 0, 12);
            collectionView.accessibilityIdentifier = @"(ACCImageAlbumCropControlView.collectionView)";
            [collectionView registerClass:[ACCImageAlbumCropRatioCell class]
               forCellWithReuseIdentifier:[ACCImageAlbumCropRatioCell cellIdentifier]];
            collectionView;
        });
    }
    return _ratioCollectionView;
}

@end
