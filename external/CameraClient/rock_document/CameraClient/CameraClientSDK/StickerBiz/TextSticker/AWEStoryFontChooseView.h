//
//  AWEStoryFontChooseView.h
//  AWEStudio
//
//  Created by li xingdong on 2019/1/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/AWEStoryTextImageModel.h>

@interface AWEStoryFontCollectionViewCell :UICollectionViewCell

@property (nonatomic, strong) AWEStoryFontModel *selectFont;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *downloadImgView;
@property (nonatomic, strong) UIImageView *loadingImgView;

- (void)startDownloadAnimation;

- (void)stopDownloadAnimationWithSuccess:(BOOL)success;

- (void)configSelect:(BOOL)select;

@end

@interface AWEStoryFontChooseView : UIView

@property (nonatomic, copy) void (^didSelectedFontBlock) (AWEStoryFontModel *selectFont, NSIndexPath *indexPath);
@property (nonatomic, strong, readonly) AWEStoryFontModel *selectFont;
@property (nonatomic, strong) UICollectionView *collectionView;

- (void)selectWithIndexPath:(NSIndexPath *)indexPath;
- (void)selectWithFontID:(NSString *)fontID;

+ (NSArray<AWEStoryFontModel *> *)stickerFonts;

@end
