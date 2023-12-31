//
//  IWKPluginObject_UIWebView.m
//  BDWebCore
//
//  Created by li keliang on 14/11/2019.
//

#import "IWKPluginObject_UIWebView.h"

@implementation IWKPluginObject_UIWebView

- (instancetype)init
{
    self = [super init];
    if (self) {
        _priority = IWKPluginObjectPriorityDefault;
        _enable = YES;
        _uniqueID = NSStringFromClass(self.class);
    }
    return self;
}

@end

