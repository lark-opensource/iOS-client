//
//  AWEVideoPublishViewModel+SourceInfo.m
//  AWEUserProfile-Pods-Aweme
//
//  Created by Yunxiang on 2020/8/22.
//

#import "AWEVideoPublishViewModel+SourceInfo.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>

@implementation AWEVideoPublishViewModel (SourceInfo)

- (BOOL)videoUploadAddSourceInfoForItem:(AVMetadataItem *)item withKey:(NSString *)key
{
    if ([item.key isKindOfClass:[NSString class]]) {
        NSString *itemKey = (NSString *)item.key;
        if ([itemKey isEqualToString:key]) {
            id itemValue = item.value;
            if ([itemValue isKindOfClass:[NSString class]]) {
                NSString *itemString = (NSString *)itemValue;
                if ([itemString length] > 0) {
                    NSData *data = [itemString dataUsingEncoding:NSUTF8StringEncoding];
                    if (data == nil) {
                        return NO;
                    }
                    if (![NSJSONSerialization isValidJSONObject:data]) {
                        return NO;
                    }
                    NSDictionary *valueInfo = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if (![valueInfo isKindOfClass:[NSDictionary class]]) {
                        return NO;
                    }
                    if (self.repoUploadInfo.sourceInfos.count == 0) {
                        AWEVideoPublishSourceInfo *sourceInfo = [AWEVideoPublishSourceInfo new];
                        sourceInfo.descriptionInfo = valueInfo;
                        [self.repoUploadInfo.sourceInfos addObject:sourceInfo];
                    }
                    return YES;
                }
            }
        }
    }
    return NO;
}

@end
