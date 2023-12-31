//
//  BDPAudioControlManager.h
//  Timor
//
//  Created by CsoWhy on 2018/7/27.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>

#import <AVFoundation/AVFoundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>

typedef NS_ENUM(NSInteger, BDPAudioInterruptionOperationType) {
    BDPAudioInterruptionOperationTypeUnknown = 0,
    // 小程序进后台
    BDPAudioInterruptionOperationTypeBackground,
    // 小程序回前台
    BDPAudioInterruptionOperationTypeForeground,
    // 小程序收到系统通知，音频被其它 App 打断
    BDPAudioInterruptionOperationTypeSystemBegan,
    // 小程序收到系统通知，音频打断已恢复
    BDPAudioInterruptionOperationTypeSystemEnd,
};

@interface BDPAudioControlManager : NSObject

+ (instancetype)sharedManager;

// Observer Switch
- (void)increaseActiveContainer;
- (void)decreaseActiveContainer;

// Interruption Functions
- (void)beginInterruption:(BDPUniqueID *)uniqueID;
- (void)endInterruption:(BDPUniqueID *)uniqueID;

@end
