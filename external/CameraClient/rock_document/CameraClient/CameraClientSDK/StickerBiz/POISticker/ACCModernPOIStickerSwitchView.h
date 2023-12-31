//
//  ACCModernPOIStickerSwitchView.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/9/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCModernPOIStickerView;

@protocol ACCModernPOIStickerSwitchViewDelegate <NSObject>

- (void)editStickerViewStyle:(ACCModernPOIStickerView *)stickerView
              didSelectIndex:(NSInteger)index
             completionBlock:(void(^)(BOOL))downloadedBlock;

- (void)selectPOIForEditStickerViewStyle;

- (void)dismissEditStickerViewStyle:(BOOL)poiChanged;

@end

@interface ACCModernPOIStickerSwitchView : UIView

@property (nonatomic, weak) id<ACCModernPOIStickerSwitchViewDelegate> delegate;

- (void)showSelectViewForSticker:(ACCModernPOIStickerView *)stickerView;
// completionBlock:animation complete
- (void)dismissSelectView:(void(^)())completionBlock;

@end

NS_ASSUME_NONNULL_END
