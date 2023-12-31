//
//  HMDUITrackableContext.h
//  HMDUITrackerRecreate
//
//  Created by bytedance on 2021/12/2.
//

#import <UIKit/UIKit.h>

@class HMDUITrackableContext;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - TrackableEvent & TrackableState

typedef NS_ENUM(NSInteger, HMDUITrackableEvents)
{
    HMDUITrackableEventCustom = 0,
    HMDUITrackableEventLoad = 1,
    HMDUITrackableEventAppear,
    HMDUITrackableEventDisappear,
    HMDUITrackableEventTrigger,
    HMDUITrackableEventSelectItem,
    HMDUITrackableEventScroll,
};

typedef NS_ENUM(NSInteger, HMDUITrackableState)
{
    HMDUITrackableStateInit = 0,
    HMDUITrackableStateLoad = 1,
    HMDUITrackableStateAppear,
    HMDUITrackableStateDisappear,
    HMDUITrackableStateUnload,
};

#pragma mark - UITrackerable 可以被追踪的数据对象 (UIView, UIViewController ...)

#pragma mark HMDUITrackable protocol
// UI 中可以被追踪的对象

@protocol HMDUITrackable <NSObject>

@property (nonatomic, strong, readonly) HMDUITrackableContext *hmd_trackContext;

- (NSString *)hmd_defaultTrackName;

- (BOOL)hmd_trackEnabled;

@end

#pragma mark NSObject (Trackable)
// 实际上每一个 NSObject 对象都可以被追踪

@interface NSObject (HMDTrackable) <HMDUITrackable>

@end

#pragma mark - TrackableContext 追踪对象的数据 (使用 objc_associatedObject 挂在对象上面)

@interface HMDUITrackableContext : NSObject

@property (nonatomic, weak) id<HMDUITrackable> trackable;
@property (nonatomic, strong) NSString *trackName;
@property (nonatomic, strong) NSDictionary *analysisInfo;
@property (nonatomic, assign) HMDUITrackableState trackableState;

- (void)trackableDidTrigger:(NSDictionary *)info;
- (void)trackableEvent:(NSString *)eventName info:(NSDictionary *)info;

- (void)trackableDidLoadWithDuration:(CFTimeInterval)duration;
- (void)trackableWillAppear;
- (void)trackableDidAppear;
- (void)trackableWillDisappear;
- (void)trackableDidDisappear;
- (void)trackableDidUnload;
- (void)trackableDidSelectItemAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
