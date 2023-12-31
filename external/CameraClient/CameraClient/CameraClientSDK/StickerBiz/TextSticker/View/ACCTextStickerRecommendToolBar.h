//
//  ACCTextStickerRecommendToolBar.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/7/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCTextStickerRecommendItem;

@interface ACCTextStickerRecommendToolBar : UIView

@property (nonatomic, copy) void(^onTitleSelected)(NSString *);
@property (nonatomic, copy) void(^onTitleExposured)(NSString *);

@property (nonatomic, copy, readonly) NSArray<ACCTextStickerRecommendItem *> *editingTitles;

- (void)updateWithTitles:(NSArray<ACCTextStickerRecommendItem *> *)titles;

@end

@interface ACCTextStickerRecommendLibView : UIView

@end

NS_ASSUME_NONNULL_END
