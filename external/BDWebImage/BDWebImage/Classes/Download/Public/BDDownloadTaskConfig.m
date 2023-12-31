//
//  BDDownloadTaskConfig.m
//  BDWebImage
//
//  Created by wby on 2021/11/2.
//

#import "BDDownloadTaskConfig.h"

@implementation BDDownloadTaskConfig

- (instancetype)init
{
  self = [super init];
  if (self) {
      _priority = NSOperationQueuePriorityNormal;
      _verifyData = YES;
      _requestHeaders = [NSDictionary dictionary];
  }
  return self;
}

@end
