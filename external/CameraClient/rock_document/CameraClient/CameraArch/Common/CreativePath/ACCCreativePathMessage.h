//
//  ACCCreativePatchMessage.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2021/4/8.
//

#import <Foundation/Foundation.h>
#import "ACCCreativePage.h"

NS_ASSUME_NONNULL_BEGIN


@protocol ACCCreativePathMessage <NSObject>

@optional

/// 进入创作路径
- (void)enterCreativePath;

/// 退出创作路径
- (void)exitCreativePath;

/// viewWillAppear 消息
- (void)creativePathPageWillAppear:(ACCCreativePage)page;

/// viewDidAppear 消息
- (void)creativePathPageDidAppear:(ACCCreativePage)page;

/// viewwilldisappear 消息
- (void)creativePathPageWillDisappear:(ACCCreativePage)page;

///  viewDidDisappear 消息
- (void)creativePathPageDidDisappear:(ACCCreativePage)page;

/// dealloc
- (void)creativePathPageDealloc:(ACCCreativePage)page;

/// 页面的其他消息
- (void)creativePathPage:(ACCCreativePage)page info:(nullable NSDictionary *)info;

@end

NS_ASSUME_NONNULL_END
