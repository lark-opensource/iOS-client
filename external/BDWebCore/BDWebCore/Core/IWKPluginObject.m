//
//  IWKPluginObject.m
//
//  Created by li keliang on 2019/6/28.
//

#import "IWKPluginObject.h"

@implementation IWKPluginObject

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
