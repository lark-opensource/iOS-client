//
//  ACCRecorderAction.h
//  BDABTestSDK
//
//  Created by leo on 2019/12/17.
//

#import <Foundation/Foundation.h>

#import <CameraClient/ACCAction.h>
#import "ACCRecorderDefine.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, ACCRecorderActionType) {
    // change record status
    ACCRecorderActionTypeStart,
    ACCRecorderActionTypePause,
    // record control flow
    ACCRecorderActionTypeRevoke,
    ACCRecorderActionTypeClear,
    ACCRecorderActionTypeCancel,
    ACCRecorderActionTypeFinish,
    ACCRecorderActionTypeRevokeAll,
    // change record mode
    ACCRecorderActionTypeChangeMode,
    // extract frame
    ACCRecorderActionTypeExtract,
    // update total duration
    ACCRecorderActionTypeUpdateDuration,
};

@interface ACCRecorderAction : ACCAction
@property (nonatomic, strong) id payload;
@end

@interface ACCRecorderAction (Create)

#pragma mark - Record Control
+ (instancetype)startAction;
+ (instancetype)startActionWithConfig:(nullable ACCRecorderConfig *)config;
+ (instancetype)pauseAction;
+ (instancetype)revokeAction;
+ (instancetype)clearAction;
+ (instancetype)revokeAllAction;
+ (instancetype)finishAction;
+ (instancetype)cancelAction;
+ (instancetype)changeModeAction:(ACCRecorderMode)mode;
+ (instancetype)extractAction;

@end

NS_ASSUME_NONNULL_END
