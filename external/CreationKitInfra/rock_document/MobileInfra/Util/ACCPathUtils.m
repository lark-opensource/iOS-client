//
//  ACCPathUtils.m
//  CameraClient-Pods-Aweme
//
// Created by Liu Bing on 2020 / 5 / 19
//

#import "ACCPathUtils.h"

NSString *ACCTemporaryDirectory(void)
{
    NSString *accTmp =[NSTemporaryDirectory() stringByAppendingPathComponent:@"acc/"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:accTmp]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:accTmp withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return accTmp;
}
