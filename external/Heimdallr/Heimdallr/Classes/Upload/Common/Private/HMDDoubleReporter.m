//
//  HMDDoubleReporter.m
//  Heimdallr
//
//  Created by bytedance on 2022/3/7.
//

#import "HMDDoubleReporter.h"
#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings.h"

@interface HMDDoubleReporter ()

@property (nonatomic, copy)NSString *doubleUploadHostAndPath;

@end

@implementation HMDDoubleReporter

+ (nonnull instancetype)sharedReporter {
    static HMDDoubleReporter *sharedReporter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedReporter = [[HMDDoubleReporter alloc] init];
    });
    return sharedReporter;
}

- (void)update:(HMDHeimdallrConfig *)config {
    HMDDoubleUploadSettings *doubleUploadSettings = config.apiSettings.doubleUploadSetting;
    self.isRunning = doubleUploadSettings.enableOpen;
    self.doubleUploadHostAndPath = [doubleUploadSettings.hostAndPath firstObject];
    self.allowPathSet = [NSSet setWithArray:doubleUploadSettings.allowList];
}

- (void)doubleUploadRecordArray:(NSArray *)records {
    if(!self.isRunning) {
        return ;
    }
    if(self.delegate && [self.delegate respondsToSelector:@selector(doubleUploadNetworkRecordArray:toURLString:)]) {
        [self.delegate doubleUploadNetworkRecordArray:records toURLString:self.doubleUploadHostAndPath];
    }
}

@end
