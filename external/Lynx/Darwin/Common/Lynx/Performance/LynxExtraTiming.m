//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxExtraTiming.h"

@implementation LynxExtraTiming

- (NSDictionary *)toDictionary {
  return @{
    @"open_time" : @(self.openTime),
    @"container_init_start" : @(self.containerInitStart),
    @"container_init_end" : @(self.containerInitEnd),
    @"prepare_template_start" : @(self.prepareTemplateStart),
    @"prepare_template_end" : @(self.prepareTemplateEnd)
  };
}

@end
