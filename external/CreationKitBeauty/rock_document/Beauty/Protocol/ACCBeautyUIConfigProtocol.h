//
//  ACCBeautyUIConfigProtocol.h
//  CameraClient
//
//  Created by zhangyuanming on 2020/8/24.
//

#import <Foundation/Foundation.h>
#import <CreationKitBeauty/ACCBeautyItemCellProtocol.h>
#import <CreationKitBeauty/ACCBeautyDefine.h>
#import <CreationKitInfra/AWERangeSlider.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCBeautyTopBarUIConfigProtocol <NSObject>

@property (nonatomic, strong) UIFont *tbSelectedTitleFont;
@property (nonatomic, strong) UIFont *tbUnselectedTitleFont;
@property (nonatomic, strong) UIColor *tbSelectedTitleColor;
@property (nonatomic, strong) UIColor *tbUnselectedTitleColor;

@end

@protocol ACCBeautyUIConfigProtocol <NSObject, ACCBeautyTopBarUIConfigProtocol>

@property (nonatomic, assign) CGFloat topBarHeight;

/// Offset from the top of beauty list
@property (nonatomic, assign) CGFloat contentCollectionViewTopOffset;

/// Height of beauty items scrolling view
@property (nonatomic, assign) CGFloat contentCollectionViewHeight;

/// Beauty panel height, excluding slide bar
@property (nonatomic, assign) CGFloat panelContentHeight;

@property (nonatomic, strong) UIColor *effectCellSelectedBorderColor;
@property (nonatomic, strong, readonly) UICollectionViewFlowLayout *effectItemsCollectionViewLayout;
/// Class should be implement ACCBeautyItemCellProtocol
@property (nonatomic, strong) Class effectItemCellClass;
@property (nonatomic, assign) AWEBeautyCellIconStyle iconStyle;
@property (nonatomic, assign) BOOL enableBeautyCategorySwitch;
@property (nonatomic, assign) ACCBeautyHeaderViewStyle headerStyle;

- (__kindof AWERangeSlider *)makeNewSlider;

@end

NS_ASSUME_NONNULL_END
