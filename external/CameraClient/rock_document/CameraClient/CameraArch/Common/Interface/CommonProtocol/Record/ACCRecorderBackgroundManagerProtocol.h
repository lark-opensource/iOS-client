//
//  ACCRecorderBackgroundManagerProtocol.h
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/10/27.
//

#import <Foundation/Foundation.h>
@protocol ACCRecordModeBackgroundModelProtocol;

typedef NS_ENUM(NSUInteger, ACCBackgroundSwitcherScene) {
    ACCBackgroundSwitcherSceneTextMode,
    ACCBackgroundSwitcherSceneAudioMode,
};

@protocol ACCRecorderBackgroundSwitcherProtocol <NSObject>

@property (nonatomic, readonly, nullable) id<ACCRecordModeBackgroundModelProtocol> currentBackground;
@property (nonatomic, readonly) NSInteger selectedIndex;// index for tracking

- (void)preloadInitBackground;
- (void)fetchAllBackgrounds;
- (void)switchToNext;
- (void)savedCurrentBackground;

@end

@protocol ACCRecorderBackgroundManagerProtocol <NSObject>

- (NSObject<ACCRecorderBackgroundSwitcherProtocol> * _Nullable)getACCBackgroundSwitcherWith:(ACCBackgroundSwitcherScene)scene;

@end
