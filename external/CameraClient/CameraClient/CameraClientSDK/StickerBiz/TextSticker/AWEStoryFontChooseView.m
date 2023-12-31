//
//  AWEStoryFontChooseView.m
//  AWEStudio
//
//  Created by li xingdong on 2019/1/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStoryFontChooseView.h"
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <KVOController/NSObject+FBKVOController.h>
#import <Masonry/View+MASAdditions.h>

static inline CGSize AWEFontCollectionCellSize(AWEStoryFontModel *fontModel)
{
    CGRect rect = [fontModel.title boundingRectWithSize:CGSizeMake(HUGE_VALF, HUGE_VALF) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: [ACCCustomFont() fontWithModel:fontModel size:14]} context:nil];
    
    CGFloat width = rect.size.width + 2 * 8;
    if (width < 64) {
        width = 64;
    }
    CGSize collectionCellSize = CGSizeMake(width, 28.0);

    return collectionCellSize;
}

@implementation AWEStoryFontCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.titleLabel];
        
        [self.contentView addSubview:self.downloadImgView];
        ACCMasMaker(self.downloadImgView, {
            make.width.equalTo(@18);
            make.height.equalTo(@18);
            make.right.equalTo(self.titleLabel).offset(2);
            make.bottom.equalTo(self.titleLabel).offset(2);
        });
        
        [self.contentView addSubview:self.loadingImgView];
        ACCMasMaker(self.loadingImgView, {
            make.width.equalTo(@18);
            make.height.equalTo(@18);
            make.center.equalTo(self.downloadImgView);
        });
        
        self.layer.cornerRadius = 4;
    }
    return self;
}

#pragma mark - Utils

- (void)startDownloadAnimation {
    self.downloadImgView.hidden = YES;
    self.loadingImgView.hidden = NO;
    [self.loadingImgView.layer removeAllAnimations];
    [self.loadingImgView.layer addAnimation:[self createRotationAnimation] forKey:@"transform.rotation.z"];
}

- (void)stopDownloadAnimationWithSuccess:(BOOL)success {
    [self.loadingImgView.layer removeAllAnimations];
    self.downloadImgView.hidden = success;
    self.loadingImgView.hidden = YES;
    
    [self refreshFont];
}

- (void)refreshFont
{
    UIFont *font = [ACCFont() systemFontOfSize:14 weight:ACCFontWeightRegular];
    if (self.selectFont.download) {
        font = [ACCCustomFont() fontWithModel:self.selectFont size:14];
    }
    
    if (self.selectFont.hasShadeColor) {
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowBlurRadius = 10;
        shadow.shadowColor = ACCUIColorFromRGBA(0xFFCC00,1.f);
        shadow.shadowOffset = CGSizeMake(0, 0);
        
        NSDictionary *params = @{NSShadowAttributeName : shadow,
                                 NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSFontAttributeName : font
                                 };
        
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:self.titleLabel.text ?: @"" attributes:params];
        self.titleLabel.attributedText = attributedString;
    } else {
        NSShadow *shadow = [[NSShadow alloc] init];
        NSDictionary *params = @{NSShadowAttributeName : shadow,
                                 NSForegroundColorAttributeName : _titleLabel.textColor,
                                 NSFontAttributeName : font
                                 };
    
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:self.titleLabel.text ?: @"" attributes:params];
            self.titleLabel.attributedText = attributedString;
    }
    
    _titleLabel.font = font;
}

- (CAAnimation *)createRotationAnimation {
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation * rotations * duration*/  ];
    rotationAnimation.duration = 0.8;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VAL;
    return rotationAnimation;
}

#pragma mark - getter

- (UIImageView *)downloadImgView
{
    if (!_downloadImgView) {
        _downloadImgView = [[UIImageView alloc] init];
        _downloadImgView.contentMode = UIViewContentModeScaleAspectFit;
        _downloadImgView.image = ACCResourceImage(@"iconStickerCellDownload");
        _downloadImgView.hidden = YES;
    }
    return _downloadImgView;
}

- (UIImageView *)loadingImgView
{
    if (!_loadingImgView) {
        _loadingImgView = [[UIImageView alloc] init];
        _loadingImgView.image = ACCResourceImage(@"iconStickerDownloading");
        _loadingImgView.hidden = YES;
    }
    return _loadingImgView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [ACCFont() systemFontOfSize:14 weight:ACCFontWeightRegular];
        _titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    }
    return _titleLabel;
}

- (void)setSelectFont:(AWEStoryFontModel *)selectFont
{
    _selectFont = selectFont;
    _titleLabel.text = selectFont.title;
    _downloadImgView.hidden = selectFont.download;
}

- (void)configSelect:(BOOL)select
{
    UIColor *color = select ? ACCResourceColor(ACCUIColorConstIconInverse2) : ACCResourceColor(ACCUIColorConstLineInverse);
    CGFloat width = select ? 2 : 1.0 / ACC_SCREEN_SCALE;
    
    if (self.selectFont.download) {
        self.downloadImgView.hidden = YES;
        self.loadingImgView.hidden = YES;
        [self refreshFont];
    } else {
        self.downloadImgView.hidden = NO;
        self.loadingImgView.hidden = YES;
    }
    
    self.layer.borderColor = color.CGColor;
    self.layer.borderWidth = width;
    
    CGSize collectionCellSize = AWEFontCollectionCellSize(self.selectFont);
    self.titleLabel.frame = CGRectMake(0, 0, collectionCellSize.width, collectionCellSize.height);
    
    self.titleLabel.accessibilityLabel = [NSString stringWithFormat:select ? @"已选择%@": @"未选择%@", self.selectFont.title];
}

- (void)refreshWithFontDownloadState {
    AWEStoryTextFontDownloadState downloadState = self.selectFont.downloadState;
    
    if (downloadState == AWEStoryTextFontUndownloaded) {
        [self stopDownloadAnimationWithSuccess:NO];
    } else if (downloadState == AWEStoryTextFontDownloading) {
        [self startDownloadAnimation];
    } else if (downloadState == AWEStoryTextFontDownloaded){
        [self stopDownloadAnimationWithSuccess:YES];
    }
}

@end


@interface AWEStoryFontChooseView() <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong, readwrite) AWEStoryFontModel *selectFont;
@property (nonatomic, assign) NSInteger selectedIndex;

@property (nonatomic, strong) NSString *lastNeedAutoSelectFontId;
@property (nonatomic, assign) BOOL firstLayouted;

@end

@implementation AWEStoryFontChooseView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumInteritemSpacing = 12;
        layout.minimumLineSpacing = 12;
        self.collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.alwaysBounceVertical = NO;
        self.collectionView.alwaysBounceHorizontal = YES;
        self.collectionView.showsVerticalScrollIndicator = NO;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.scrollEnabled = YES;
        [self.collectionView registerClass:[AWEStoryFontCollectionViewCell class] forCellWithReuseIdentifier:@"AWEStoryFontCollectionViewCell"];
        [self addSubview:self.collectionView];
        ACCMasMaker(self.collectionView, {
            make.edges.equalTo(self);
        });
        if (!ACC_isEmptyArray(self.stickerFonts)) {
            [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
        
        self.selectFont = self.stickerFonts.firstObject;
        self.selectedIndex = 0;
    }
    return self;
}

- (void)dealloc
{
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
    _collectionView = nil;
}

- (void)selectWithIndexPath:(NSIndexPath *)indexPath
{
    if (ACC_isEmptyArray(self.stickerFonts)) {
        return;
    }
    AWEStoryFontCollectionViewCell *lastSelectedCell = (AWEStoryFontCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]];
    [lastSelectedCell configSelect:NO];
    self.selectFont = [self.stickerFonts objectAtIndex:indexPath.row];
    self.selectedIndex = indexPath.row;
    AWEStoryFontCollectionViewCell *selectedCell = (AWEStoryFontCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [selectedCell configSelect:YES];
    [self.collectionView reloadData];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    self.lastNeedAutoSelectFontId = nil;
}

- (void)selectWithFontID:(NSString *)fontID
{
    if (ACC_isEmptyString(fontID)) {
        return;
    }
    
    NSArray<AWEStoryFontModel *> *fontArray = self.stickerFonts.copy;
    for (int i = 0; i < fontArray.count; i++) {
        if ([fontArray[i].effectId isEqual:fontID]) {
            [self selectWithIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            break;
        }
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.stickerFonts.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWEStoryFontCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AWEStoryFontCollectionViewCell" forIndexPath:indexPath];
    cell.selectFont = self.stickerFonts[indexPath.row];
    [cell refreshWithFontDownloadState];

    __weak typeof(cell) weakCell = cell;
    [cell.KVOController unobserveAll];
    [cell.KVOController observe:cell.selectFont keyPath:@"downloadState" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        // refreshWithFontDownloadState 中会进行UI操作
        acc_dispatch_main_async_safe(^{
            [weakCell refreshWithFontDownloadState];
        });
    }];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(AWEStoryFontCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [cell configSelect:indexPath.row == self.selectedIndex];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    __block AWEStoryFontModel *model = [self.stickerFonts objectAtIndex:indexPath.row];
    if (model.download) {
        self.lastNeedAutoSelectFontId = nil;
        AWEStoryFontCollectionViewCell *lastSelectedCell = (AWEStoryFontCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]];
        [lastSelectedCell configSelect:NO];
        self.selectFont = [self.stickerFonts objectAtIndex:indexPath.row];
        ACCBLOCK_INVOKE(self.didSelectedFontBlock, self.selectFont, indexPath);
        self.selectedIndex = indexPath.row;
        AWEStoryFontCollectionViewCell *selectedCell = (AWEStoryFontCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [selectedCell configSelect:YES];
    } else {
        self.lastNeedAutoSelectFontId = model.effectId;
        AWEStoryFontCollectionViewCell *cell = (AWEStoryFontCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        [cell startDownloadAnimation];

        if (model.downloadState == AWEStoryTextFontUndownloaded) {
            @weakify(self);
            [ACCCustomFont() downloadFontWithModel:model completion:^(NSString *filePath, BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell stopDownloadAnimationWithSuccess:success];
                    if (ACC_isEmptyString(filePath) || !success) {

                        model.localUrl = nil;
                        [ACCToast() show:ACCLocalizedCurrentString(@"creation_text_textfile_load_fail")];
                    } else {
                        model.localUrl = filePath;
                        @strongify(self);
                        // 点击的字体下载完成以后如果没有选择其他的文字 则自动选中该字体
                        if (!ACC_isEmptyString(self.lastNeedAutoSelectFontId) && [model.effectId isEqualToString:self.lastNeedAutoSelectFontId]) {
                            [self selectWithFontID:model.effectId];
                            if (self.selectFont) {
                                ACCBLOCK_INVOKE(self.didSelectedFontBlock, self.selectFont, [NSIndexPath indexPathForRow:self.selectedIndex inSection:0]);
                            }
                        }
                        self.lastNeedAutoSelectFontId = nil;
                    }
                });
            }];
        }
    }
    
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.stickerFonts.count) {
        AWEStoryFontModel *currentFontModel = self.stickerFonts[indexPath.row];
        return AWEFontCollectionCellSize(currentFontModel);
    }
    return CGSizeZero;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!self.firstLayouted && !CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        self.firstLayouted = YES;
        if (self.selectedIndex < self.stickerFonts.count) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
    }
}

+ (NSArray<AWEStoryFontModel *> *)stickerFonts
{
    return ACCCustomFont().stickerFonts;
}

#pragma mark - getter

- (NSArray<AWEStoryFontModel *> *)stickerFonts
{
    return [[self class] stickerFonts];
}

@end
