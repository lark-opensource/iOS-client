//
//  BDWebSecureLinkCustomSetting.m
//  BDWebKit
//
//  Created by bytedance on 2020/5/6.
//

#import "BDWebSecureLinkCustomSetting.h"

@implementation BDWebSecureLinkCustomSetting

- (instancetype)init {
    if (self = [super init]) {
        self.errorOverwhelmingCount = 3;
        self.errorOverwhelmingDuration = 1800;
        self.safeDuraionAfterOverWhelming = 1800;
        self.syncCheckTimeLimit = 1.0;
        self.area = BDSecureLinkAreaOptionInline;
    }
    return self;
}

- (void)setSyncCheckTimeLimit:(float)syncCheckTimeLimit {
    _syncCheckTimeLimit = syncCheckTimeLimit > 3 ? 3 : syncCheckTimeLimit;
}

@end
