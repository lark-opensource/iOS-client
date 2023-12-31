//
//  AWECountDownBarChartView.h
//  Pods
//
//  Created by jindulys on 2019/5/26.
//

#import "AWEScrollBarChartView.h"

@interface AWECountDownBarChartView : AWEScrollBarChartView

@property (nonatomic, copy) void(^updateMusicBlock)(void);

@property (nonatomic, strong) UIColor *recordedColor;
@property (nonatomic, strong) UIColor *countDownColor;
@property (nonatomic, strong) UIColor *unReachedColor;
@property (nonatomic, assign) CGFloat hasRecordedLocation;
@property (nonatomic, assign) CGFloat countDownLocation;

@end
