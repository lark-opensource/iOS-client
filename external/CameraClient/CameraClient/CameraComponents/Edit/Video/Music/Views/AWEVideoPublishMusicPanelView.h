//
//  AWEVideoPublishMusicPanelView.h
//  AWEStudio
//
//  Created by Nero Li on 2019/1/9.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CameraClient/ACCMusicPanelViewProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEVideoPublishMusicPanelView : UIView <ACCMusicPanelViewProtocol>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
