//
//  ACCPropPickerView.h
//  CameraClient
//
//  Created by Shen Chen on 2020/4/1.
//  Copyright © 2020 Shen Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCPropPickerViewScrollReason) {
    ACCPropPickerViewScrollReasonTap = 0,
    ACCPropPickerViewScrollReasonDrag,
    ACCPropPickerViewScrollReasonProgram
};

@class ACCPropPickerView;
@protocol ACCPropPickerViewDelegate <NSObject>
- (void)pickerView:(ACCPropPickerView *)pickerView didChangeCenteredIndex:(NSInteger)index scrollReason:(ACCPropPickerViewScrollReason)reason;
- (void)pickerView:(ACCPropPickerView *)pickerView didPickIndexByTap:(NSInteger)index;
- (void)pickerView:(ACCPropPickerView *)pickerView didPickIndexByDragging:(NSInteger)index;
- (void)pickerView:(ACCPropPickerView *)pickerView didEndAnimationAtIndex:(NSInteger)index;
- (void)pickerViewWillBeginDragging:(ACCPropPickerView *)pickerView;
- (void)pickerView:(ACCPropPickerView *)pickerView willDisplayIndex:(NSInteger)index;
@end

@interface ACCPropPickerView : UIView
@property (nonatomic, assign, readonly) NSInteger selectedIndex;
@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong) UIColor *homeTintColor;
@property (nonatomic, assign) BOOL showHomeIcon;
@property (nonatomic, assign) BOOL isMeteorMode;
@property (nonatomic, weak) UIView *indicatorView;
@property (nonatomic, assign) NSUInteger homeIndex;
@property (nonatomic, weak) id<UICollectionViewDataSource> dataSource;
@property (nonatomic, weak) id<ACCPropPickerViewDelegate> delegate;
- (void)reloadData;
- (void)updateSelectedCellAtIndex:(NSInteger)index showProgress:(BOOL)show progress:(CGFloat)progress;
- (void)updateSelectedIndex:(NSInteger)index animated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END
