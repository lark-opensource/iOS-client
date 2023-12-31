//
//  ACCSelectMusicTabProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/6/30.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ACCSelectMusicTabType) {
    ACCSelectMusicTabTypeHot,
    ACCSelectMusicTabTypeCollect,
    ACCSelectMusicTabTypeLocal
};


typedef void(^ACCSelectMusicTabCompletion)(ACCSelectMusicTabType selectedIndex);
typedef BOOL(^ACCSelectMusicTabShouldSelect)(ACCSelectMusicTabType selectedIndex);

@protocol ACCSelectMusicTabProtocol <NSObject>

@property (nonatomic, copy) ACCSelectMusicTabCompletion tabCompletion;
@property (nonatomic, copy) ACCSelectMusicTabShouldSelect tabShouldSelect;


- (ACCSelectMusicTabType)selectedTabType;

- (void)showBottomLineView:(BOOL)show;

/**
 * @brief 存量接口
 * use by code  强制驱动UI切换至指定tab 会自动执行后续commit和block
 * 谨慎使用！
 */
- (void)forceSwitchSelectedType:(ACCSelectMusicTabType)selectedType;

@end

