//
//  BDPToastPluginModel.m
//  Timor
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import "BDPToastPluginModel.h"

@implementation BDPToastPluginModel

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    if (self = [super initWithDictionary:dict error:err]) {
        if (dict[@"duration"] == nil) {
            self.duration = 1500; // 默认值1500毫秒
        }
        if (dict[@"icon"] == nil) {
            self.icon = @"success"; // 默认success
        }
    }
    return self;
}

@end
