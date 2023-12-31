//
//  AWEStickerPickerFavoriteView.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/5/20.
//

#import <UIKit/UIKit.h>
#import <CameraClient/ACCCollectionButton.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 收藏按钮
 */
@interface AWEStickerPickerFavoriteView : UIView

@property (nonatomic, strong, readonly) ACCCollectionButton *favoriteButton;

@property (nonatomic, assign) BOOL selected;

- (void)toggleSelected;

@end

NS_ASSUME_NONNULL_END
