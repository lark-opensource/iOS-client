//
//  ACCMusicPanelToolbar.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/6/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicPanelBottomToolbarDelegate <NSObject>

@optional

- (BOOL)toolbarMusicScoreSelected:(BOOL)isSelected;
- (void)toolbarOriginMusicSelected:(BOOL)isSelected;
- (void)toolbarVolumeTapped;

@end

@interface ACCMusicPanelBottomToolbar : UIView

@property (nonatomic, assign) BOOL musicScoreSelected;
@property (nonatomic, assign) BOOL musicScoreDisable;
@property (nonatomic, assign) BOOL musicScoreHide;

@property (nonatomic, assign) BOOL originMusicSelected;
@property (nonatomic, assign) BOOL originMusicDisable;
@property (nonatomic, assign) BOOL originMusicScoreHide;

@property (nonatomic, assign) BOOL volumeDisable;
@property (nonatomic, assign) BOOL volumeHide;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame isDarkBackground:(BOOL)isDarkBackground delegate:(id<ACCMusicPanelBottomToolbarDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (void)hiddenOriginMusicView;

@end

NS_ASSUME_NONNULL_END
