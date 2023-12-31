//
//  ACCLocalAudioUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/4.
//

#import "ACCLocalAudioUtils.h"

@implementation ACCLocalAudioUtils

+ (BOOL)isContainIncorrectChar:(NSString *)content
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"([%@]+)", [self validMusicNameCharset]] options:0 error:nil];
    NSArray<NSTextCheckingResult *> *arr = [regex matchesInString:content options:NSMatchingReportCompletion range:NSMakeRange(0, content.length)];
    NSTextCheckingResult *firstMatchResult = [regex firstMatchInString:content options:NSMatchingReportCompletion range:NSMakeRange(0, content.length)];
    if ((arr.count == 1) && (!firstMatchResult.range.location) && (firstMatchResult.range.length == content.length)) {
        return NO;
    } else {
        return YES;
    }
}

+ (NSString *)validMusicNameCharset
{
    return @"\\u0030-\\u0039\\u0041-\\u005A\\u005F\\u0061-\\u007A\\u00C0-\\u02B8\\u0370-\\u058F\\u0600-\\u077F\\u0900-\\u1DBF\\u1E00-\\u1FFF\\u2150-\\u218F\\u2C00-\\u2DDF\\u2E80-\\u2FDF\\u3040-\\u31FF\\u3400-\\u4DBF\\u4E00-\\uA6FF\\uA720-\\uABFF\\uAC00-\\uD7A3";
}

@end
