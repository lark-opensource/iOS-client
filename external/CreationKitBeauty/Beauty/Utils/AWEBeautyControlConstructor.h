//
//  AWEBeautyControlConstructer.h
//  CameraClient-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/6/30.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/AWESlider.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEBeautyControlConstructor : NSObject

+ (AWESlider *)slider;

+ (UIButton *)resetButton;

+ (UICollectionView *)beautyCollectionView;

+ (CGFloat)collectionViewSpacingForCellNumber:(NSInteger)cellNumber;

+ (CGFloat)collectionViewInsetMarginForCellNumber:(NSInteger)cellNumber;

@end

NS_ASSUME_NONNULL_END
