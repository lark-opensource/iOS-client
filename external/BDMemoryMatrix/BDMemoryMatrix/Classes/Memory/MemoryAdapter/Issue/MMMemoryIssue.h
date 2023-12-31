//
//  MMMemoryIssue.h
//  Pods-IESDetection_Example
//
//  Created by zhufeng on 2021/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMMemoryIssue : NSObject

/// the issue's unique identifier
@property (nonatomic, copy) NSString *issueID;

@property (nonatomic, strong) NSData *issueData;

@property (nonatomic, strong) NSDictionary *customInfo;

@end

NS_ASSUME_NONNULL_END
