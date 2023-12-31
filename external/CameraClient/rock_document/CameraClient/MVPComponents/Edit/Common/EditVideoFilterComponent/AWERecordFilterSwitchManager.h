//
//  AWERecordFilterSwitchManager.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/3/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTVideoEditor/IESMMBaseDefine.h>
#import <TTVideoEditor/HTSFilterDefine.h>

@class IESEffectModel;
@class AWECameraFilterConfiguration;

#pragma mark - typedef

typedef void(^AWERecordFilterApplyCompletionBlock)(IESEffectModel *filter);
typedef void(^AWERecordFilterChangeProgressBlock)(IESEffectModel *leftFilter, IESEffectModel *rightFilter, CGFloat progress);


#pragma mark - AWERecordFilterSwitchProtocol
/**
 想要添加手势滑动切换滤镜的Controller需要遵守的协议
 */
@protocol AWERecordFilterSwitchProtocol <NSObject>

- (void)switchFilterWithFilterOne:(IESEffectModel *)filterOne
                        FilterTwo:(IESEffectModel *)filterTwo
                        direction:(IESMMFilterSwitchDirection)direction
                         progress:(CGFloat)progress;

@property (nonatomic, assign) BOOL enableFilterSwitch;

- (BOOL)switchFilterGestureShouldBegin;

@optional

- (void)applyFilterWithFilterModel:(IESEffectModel *)filterModel type:(IESEffectType)type;

@end


#pragma mark AWERecordFilterSwitchManager

@interface AWERecordFilterSwitchManager : NSObject

@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGes;
@property (nonatomic, copy) AWERecordFilterApplyCompletionBlock completionBlock;
@property (nonatomic, copy) AWERecordFilterChangeProgressBlock changeProgressBlock;
@property (nonatomic, assign) CGRect gestureResponseArea;//滑动切换滤镜响应区域
@property (nonatomic, weak) id<AWERecordFilterSwitchProtocol> delegate;

/**
 向controller添加滑动切换滤镜的手势

 @param controller 需要添加滑动切换滤镜的手势
 @param filterArray 可供滑动使用的滤镜数组
 @param filterConfiguration filter配置
 */
- (void)addFilterSwitchGestureForViewController:(UIViewController *)controller
                                    filterArray:(NSArray *)filterArray
                            filterConfiguration:(AWECameraFilterConfiguration *)filterConfiguration;

/**
 开启切换完成或取消后的切换动画
 */
- (void)startSwitchDisplayLink;

/**
 关闭切换完成或取消后的切换动画
 */
- (void)stopSwitchDisplayLink;

/**
 除AWERecordFilterSwitchManager调用camera应用滤镜完成外，每次外部调用camera应用完滤镜都应该使用应用完成的滤镜进行刷新

 @param filter 外部应用完成的滤镜模型
 */
- (void)refreshCurrentFilterModelWithFilter:(IESEffectModel *)filter;

/**
 开关滑动切滤镜手势
 */
- (void)updatePanGestureEnabled:(BOOL)enabled;

//Force current switch process to stop
- (void)finishCurrentSwitchProcess;

/**
 Pan gesture should ignore some views, which will be stored in self.panGesExcludeViews
 */
- (void)addPanGesExcludedView:(UIView *)exludedView;

@end
