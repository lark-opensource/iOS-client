//
//  NSDate+ACCAdditions.m
//  CameraClient
//
//  Created by Liu Deping on 2019/12/4.
//

#import "NSDate+ACCAdditions.h"

@implementation NSDate (ACCAdditions)

- (NSString *)acc_stringWithFormat:(NSString *)format
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:format];
    [formatter setLocale:[NSLocale currentLocale]];
    return [formatter stringFromDate:self];
}

- (NSInteger)acc_dateInteger
{
    return [[self acc_stringWithFormat:@"YYYYMMDD"] integerValue];
}

@end
