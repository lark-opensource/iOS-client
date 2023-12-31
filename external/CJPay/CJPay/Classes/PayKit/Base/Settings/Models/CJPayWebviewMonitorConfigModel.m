//
//  CJPayWebviewMonitorConfigModel.m
//  Pods
//
//  Created by 尚怀军 on 2021/7/27.
//

#import "CJPayWebviewMonitorConfigModel.h"

@implementation CJPayWebviewMonitorConfigModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"detectBlankDelayTime" : @"blank_screen_detect_delay_time",
                @"webviewPageTimeoutTime": @"wallet_rd_webview_page_timeout",
                @"enableMonitor": @"enable_monitor"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
