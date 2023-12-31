//
//  ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/2/18.
//

#import "AWEStudioBaseCollectionViewCell.h"

#import "ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel.h"

NS_ASSUME_NONNULL_BEGIN

extern CGFloat const kTextReaderSoundEffectsSelectionBottomCollectionViewCellWidth;
extern CGFloat const kTextReaderSoundEffectsSelectionBottomCollectionViewCellHeight;

@interface ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell : AWEStudioBaseCollectionViewCell

- (void)configCellWithModel:(ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *)model;
- (void)updateUIStatus;

@end

NS_ASSUME_NONNULL_END
