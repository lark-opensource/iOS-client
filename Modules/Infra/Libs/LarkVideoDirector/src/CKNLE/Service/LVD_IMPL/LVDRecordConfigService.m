//
//  LVDRecordConfigService.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/21.
//

#import "LVDRecordConfigService.h"
#import <CreationKitArch/ACCRepoContextModel.h>

@implementation LVDRecordConfigService

- (CGFloat)videoMaxDuration {
    // 暂时没看到其他使用这个属性的地方，借用来存自定义时长
    double customMaxDuration = self.publishModel.repoContext.maxDuration;
    if (customMaxDuration <= 1) {
        return 30; // 默认 30s
    } else {
        return customMaxDuration;
    }
}

- (CGFloat)videoMinDuration {
    return 1;
}

@end
