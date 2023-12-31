//
//  BDPModalPluginModel.m
//  Timor
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import "BDPModalPluginModel.h"
#import <ECOInfra/NSString+BDPExtension.h>
#import "BDPI18n.h"

static const BOOL kShowCancelDefault = YES;
static const NSInteger kButtonMaxWordLength = 4;

@implementation BDPModalPluginModel

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err
{
    self = [super initWithDictionary:dict error:err];
    if (self) {
        [self fixShowCancelWithDict:dict];
        [self fixCancelTextIfNeeded];
        [self fixConfirmTextIfNeeded];
    }
    return self;
}

- (void)fixCancelTextIfNeeded
{
    if (!_showCancel) {
        return;
    }
    
    if (!_cancelText.length) {
        _cancelText = BDPI18n.cancel;
    }
    
    _cancelText = [_cancelText bdp_subStringForMaxWordLength:kButtonMaxWordLength withBreak:NO];
}

- (void)fixConfirmTextIfNeeded
{
    if (!_confirmText.length) {
        _confirmText = BDPI18n.determine;
    }
    
    _confirmText = [_confirmText bdp_subStringForMaxWordLength:kButtonMaxWordLength withBreak:NO];
}

- (void)fixShowCancelWithDict:(NSDictionary *)dict
{
    //这里case上要求showCancel的默认值是YES，
    //除非传过来的参数是0，否则都是保持默认值
    BOOL showCancel = kShowCancelDefault;
    id showCancelObj = [dict objectForKey:@"showCancel"];
    //这里兼容一下字符串的"0"
    if ([showCancelObj isKindOfClass:NSString.class]) {
        if ([showCancelObj isEqualToString:@"0"]) {
            showCancel = NO;
        }
    } else if ([showCancelObj isKindOfClass:NSNumber.class]) {
        if (![showCancelObj boolValue]) {
            showCancel = NO;
        }
    }
    
    _showCancel = showCancel;
}

@end
