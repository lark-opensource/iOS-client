//
//  NLENode_OC+ACCAdditions.m
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/9.
//

#import "NLENode_OC+ACCAdditions.h"
#import <CreationKitInfra/ACCLogHelper.h>

@implementation NLENode_OC (ACCAdditions)

- (NSObject *)getValueFromDouyinExtraWithKey:(NSString *)key
{
    if (key == nil) {
        return nil;
    }
    
    NSString *extraStr = [self getExtraForKey:@"douyin"];
    NSData *extraData = [extraStr dataUsingEncoding:NSUTF8StringEncoding];
    if (extraData == nil) {
        return nil;
    }
    NSError *error = nil;
    NSDictionary *extraDict = [NSJSONSerialization JSONObjectWithData:extraData options:kNilOptions error:&error];
    if (error) {
        AWELogToolError(AWELogToolTagEdit, @"%s %@", __PRETTY_FUNCTION__, error);
    }
    
    return extraDict[key];
}

@end
