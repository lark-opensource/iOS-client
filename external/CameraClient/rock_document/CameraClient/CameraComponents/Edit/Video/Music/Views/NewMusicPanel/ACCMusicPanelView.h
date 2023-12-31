//
//  ACCMusicPanelView.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/6/24.
//

#import <UIKit/UIKit.h>
#import <CameraClient/ACCMusicPanelViewProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMusicPanelView : UIView <ACCMusicPanelViewProtocol>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
