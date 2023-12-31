//
//  ACCSwitchLengthView.h
//  DouYin
//
//  Created by shaohua yang on 6/29/20.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ACCSwitchLengthCell.h"
#import "ACCRecordSubmodeViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCRecordContainerMode;
@class ACCRecordMode;

@protocol ACCSwitchLengthViewDelegate <NSObject>

/// 内部模式变化后通知component的回调
/// @param index 切换到的index
/// @param method 内部切换方式，用于埋点
- (void)modeIndexDidChangeTo:(NSInteger)index method:(submodeSwitchMethod)method;

@end

@interface ACCSwitchLengthView : UIView

@property (nonatomic, weak) id<ACCSwitchLengthViewDelegate> delegate;
@property (nonatomic, weak) ACCRecordContainerMode *containerMode;
@property (nonatomic, assign) BOOL needForceSwitch;

/// 设置当前需要显示的模式index
/// @param currentModeIndex 需要显示的index
/// @param animated 是否需要动画
- (void)setModeIndex:(NSInteger)currentModeIndex animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
