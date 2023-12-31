//
//  ACCRecordSubmodeViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Kevin Chen on 2020/12/21.
//

#import <CreationKitArch/ACCRecorderViewModel.h>

#import <CreativeKit/ACCRecorderViewContainer.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, submodeSwitchMethod) {
    submodeSwitchMethodTabBarSlide = 0,
    submodeSwitchMethodTabBarClick,
    submodeSwitchMethodFullScreenSlide,
    submodeSwitchMethodClickCross,
};

@class ACCRecordMode, ACCRecordContainerMode;

@interface ACCRecordSubmodeViewModel : ACCRecorderViewModel <UIGestureRecognizerDelegate>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, weak) ACCRecordContainerMode *containerMode;
@property (nonatomic, assign) CGRect gestureResponseArea;
@property (nonatomic, assign) BOOL swipeGestureEnabled;
@property (nonatomic, assign) NSInteger modeIndex;
@property (nonatomic, assign) BOOL switchLengthViewHidden;
@property (nonatomic, assign) BOOL quickAlbumShow;

// for track
@property (nonatomic, assign) submodeSwitchMethod switchMethod;
@property (nonatomic, readonly) NSString *switchMethodString;

/// 横滑切换模式手势处理
/// @param gestureRecognizer
- (void)swipeSwitchSubmode:(UIPanGestureRecognizer *)gestureRecognizer;
- (void)close;

@end

NS_ASSUME_NONNULL_END
