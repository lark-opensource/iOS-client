//
//  AWEStickerPickerLogMarcos.h
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/10/19.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEStickerPickerLogger.h>

#ifndef AWESTICKER_LOG
#define AWESTICKER_LOG(level, frmt, ...) \
        [[AWEStickerPickerLogger sharedInstance] \
                                 logLevel:level  \
                                   format:(frmt), ## __VA_ARGS__];
#endif

#define AWEStickerPickerLogError(frmt, ...)   AWESTICKER_LOG(AWEStickerPickerLogLevelError,   frmt, ##__VA_ARGS__)
#define AWEStickerPickerLogWarn(frmt, ...)    AWESTICKER_LOG(AWEStickerPickerLogLevelWarning, frmt, ##__VA_ARGS__)
#define AWEStickerPickerLogInfo(frmt, ...)    AWESTICKER_LOG(AWEStickerPickerLogLevelInfo,    frmt, ##__VA_ARGS__)
#define AWEStickerPickerLogDebug(frmt, ...)   AWESTICKER_LOG(AWEStickerPickerLogLevelDebug,   frmt, ##__VA_ARGS__)
#define AWEStickerPickerLogVerbose(frmt, ...) AWESTICKER_LOG(AWEStickerPickerLogLevelVerbose, frmt, ##__VA_ARGS__)

