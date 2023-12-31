//
//  IESGurdPollingRequest.m
//  BDAssert
//
//  Created by 陈煜钏 on 2020/8/31.
//

#import "IESGurdPollingRequest.h"
#import "IESGurdKit+Experiment.h"
#import "IESGurdKitUtil.h"

@interface IESGurdPollingRequest ()

@property (nonatomic, readwrite, assign) IESGurdPollingPriority priority;

@end

@implementation IESGurdPollingRequest

#pragma mark - Public

+ (instancetype)requestWithPriority:(IESGurdPollingPriority)priority
{
    IESGurdPollingRequest *request = [[self alloc] init];
    request.priority = priority;
    request.requestType = IESGurdPackagesConfigRequestTypePolling;
    request.modelActivePolicy = IESGurdPackageModelActivePolicyFilterLazy;
    return request;
}

#pragma mark - NSObject

- (NSString *)description
{
    NSString *description = [super description] ? : @"";
    return [NSString stringWithFormat:@"%@ priority : %zd", description, self.priority];
}

#pragma mark - IESGurdPackageBaseRequestSubclass

- (NSDictionary *)requestMetaDictionary
{
    return @{ @"req_type" : @(self.requestType),
              @"combine_level" : IESGurdPollingPriorityString(self.priority) };
}

- (NSDictionary *)logInfo
{
    return @{ @"req_type" : @(self.requestType),
              @"api_version" : @"combine_v3" };
}

@end
