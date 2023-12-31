//
//  MMMemoryIssue.m
//  Pods-IESDetection_Example
//
//  Created by zhufeng on 2021/8/25.
//

#import "MMMemoryIssue.h"

@implementation MMMemoryIssue

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"issueID = %@ , issueDataSize = %@ , customInfo = %@",
            self.issueID,
            @(self.issueData.length),
            self.customInfo
            ];
}

@end
