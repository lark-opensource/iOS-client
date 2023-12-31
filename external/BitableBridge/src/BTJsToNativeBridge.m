//
//  JsToNativeBridge.m
//  BitableBridge
//
//  Created by maxiao on 2018/9/13.
//

#import "BTJsToNativeBridge.h"
#import <React/RCTLog.h>
#import "NSData+BitableBridge.h"

@implementation BTJsToNativeBridge

RCT_EXPORT_MODULE(JsToNativeBridge)

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(responseFromJs:(NSString *)pbDataString)
{
    if ([self.delegate respondsToSelector:@selector(didReceivedResponse:)]) {
        [self.delegate didReceivedResponse:pbDataString];
    }
}

RCT_EXPORT_METHOD(responseFromDocs:(NSString *)jsonString)
{
    if ([self.delegate respondsToSelector:@selector(didReceivedDocsResponse:)]) {
        [self.delegate didReceivedDocsResponse:jsonString];
    }
}

@end
