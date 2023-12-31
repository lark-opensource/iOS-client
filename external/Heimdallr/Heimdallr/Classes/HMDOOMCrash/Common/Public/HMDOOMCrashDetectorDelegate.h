//
//  HMDOOMCrashDetectorDelegate.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/3/14.
//

#import <Foundation/Foundation.h>
#import "HMDAPPExitReasonDetectorProtocol.h"

/// 检测到上次启动发生了 FOOM（通知会在主线程发出），userinfo包含对应的{"record":HMDOOMCrashRecord}
OBJC_EXTERN NSString * _Nonnull const HMDDidDetectOOMCrashNotification;

@protocol HMDOOMCrashDetectorDelegate <NSObject>

@property (nonatomic, assign) HMDApplicationRelaunchReason reason;

@optional
- (void)crashDetectorDidDetectOOMCrashWithData:(HMDOOMCrashInfo *_Nonnull)info;
- (void)crashDetectorDidNotDetectOOMCrashWithRelaunchReason:(HMDApplicationRelaunchReason)reason;

@end
