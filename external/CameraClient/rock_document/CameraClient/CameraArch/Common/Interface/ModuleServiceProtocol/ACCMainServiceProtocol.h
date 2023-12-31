//
//  ACCMainServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2020/10/14.
//

#ifndef ACCMainServiceProtocol_h
#define ACCMainServiceProtocol_h

#import <Foundation/Foundation.h>

@protocol ACCMainServiceProtocol <NSObject>

- (NSString *)lastHomePagePlayingAwemeID;

/**
 * @return whether the user preload switch is open or not.
 */
- (BOOL)isUserPreuploadEnabled;

/**
 * @return 是否打开个性化推荐开关
 */
- (BOOL)isPersonalRecommendSwitchOn;

/**
 * @return 当前是否打开青少年模式
 * ACCUserService里的isChildMode在studio中的实现有问题，先用该方法替代，后面统一修改
 */
- (BOOL)isTeenModeEnabled;

@end

#endif /* ACCMainServiceProtocol_h */
