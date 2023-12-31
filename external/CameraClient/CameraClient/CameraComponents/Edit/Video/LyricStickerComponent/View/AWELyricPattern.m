

//
//  AWELyricPattern.m
//  Aweme
//
//  Created by Nero on 2019/1/9.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "AWELyricPattern.h"

@implementation AWELyricPattern

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"timeId" : @"timeId",
             @"lyricText" : @"text"
             };
}

- (NSTimeInterval)timestamp {
    return self.timeId.doubleValue;
}

@end
