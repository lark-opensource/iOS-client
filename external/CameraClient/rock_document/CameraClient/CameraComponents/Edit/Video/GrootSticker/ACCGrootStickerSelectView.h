//
//  ACCGrootStickerSelectView.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/17.
//

#import <UIKit/UIKit.h>
#import "ACCGrootStickerModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCGrootStickerSelectViewDelegate <NSObject>

- (void)selectedGrootStickerModel:(ACCGrootDetailsStickerModel *)model index:(NSUInteger)index;
- (void)didClickedSaveButtonAction:(BOOL)allowed;
- (void)didClickCancelButtonAction;
- (void)didClickAllowResearchButtonAction:(BOOL)allowed;
- (void)didSlideCard;

@end

@interface ACCGrootStickerSelectCell : UICollectionViewCell

- (void)configGrootStickerModel:(ACCGrootDetailsStickerModel *)model grootModels:(NSArray<ACCGrootDetailsStickerModel *> *)models;

@end

@interface ACCGrootStickerSelectView : UIView

+ (CGSize)adaptionCollectionViewSize;

- (void)configData:(NSArray<ACCGrootDetailsStickerModel *> *)models selectedModel:(ACCGrootDetailsStickerModel *)selectedModel allowResearch:(BOOL)allowResearch delegate:(id<ACCGrootStickerSelectViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
