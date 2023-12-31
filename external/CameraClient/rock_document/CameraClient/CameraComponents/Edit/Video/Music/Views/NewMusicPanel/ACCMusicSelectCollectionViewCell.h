//
//  ACCMusicSelectCollectionViewCell.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/7/5.
//

#import "AWEPhotoMusicEditorCollectionViewCell.h"
@class ACCMusicSelectCollectionViewCell;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicSelectCollectionViewCellDelegate <NSObject>

- (void)updateCellActionStatus:(ACCMusicSelectCollectionViewCell *)musicCell;
- (void)cellFavoriteButtonTapped:(UIButton *)sender;
- (void)cellClipMusicButtonTapped:(UIButton *)sender;
- (void)cellToggleLyricStickerTapped:(UIButton *)sender;

@end

@interface ACCMusicSelectCollectionViewCell : AWEPhotoMusicEditorCollectionViewCell

@property (nonatomic, weak) id<ACCMusicSelectCollectionViewCellDelegate> delegate;

- (void)updateMusicName:(NSString *)musicName author:(NSString *)author isPGC:(BOOL)isPgc matchedPGCTitle:(NSString *)pgcTitle;

- (void)setIsCurrent:(BOOL)isCurrent animated:(BOOL)animated completion:(void (^ __nullable)(BOOL))completion needForceUpdate:(BOOL)forceUpdate;

- (void)updateLyricStickerButtonStatus:(UIButton *)button;
- (void)updateClipButtonStatus:(UIButton *)button;
- (void)updateFavoriteButtonStatus:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
