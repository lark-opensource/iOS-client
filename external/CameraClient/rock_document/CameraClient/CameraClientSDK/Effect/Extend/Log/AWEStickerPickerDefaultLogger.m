//
//  AWEStickerPickerDefaultLogger.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangchengtao on 2020/12/3.
//

#import "AWEStickerPickerDefaultLogger.h"
#import <CreationKitInfra/ACCLogProtocol.h>

@implementation AWEStickerPickerDefaultLogger

#pragma mark - AWEStickerPickerLoggerDelegate

- (void)stickerPickerLogger:(AWEStickerPickerLogger *)logger logMessage:(NSString *)logMessage level:(AWEStickerPickerLogLevel)level
{
    switch (level) {
        case AWEStickerPickerLogLevelError: {
            AWELogToolError(AWELogToolTagNone, @"%@", logMessage);
            break;
        }
        case AWEStickerPickerLogLevelWarning: {
            AWELogToolWarn(AWELogToolTagNone, @"%@", logMessage);
            break;
        }
        case AWEStickerPickerLogLevelInfo: {
            AWELogToolInfo(AWELogToolTagNone, @"%@", logMessage);
            break;
        }
        case AWEStickerPickerLogLevelDebug: {
            AWELogToolDebug(AWELogToolTagNone, @"%@", logMessage);
            break;
        }
        case AWEStickerPickerLogLevelVerbose: {
            AWELogToolVerbose(AWELogToolTagNone, @"%@", logMessage);
            break;
        }
        default:
            break;
    }
}

@end
