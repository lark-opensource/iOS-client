//
//  HTSBootConfiguration.m
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/16.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "HTSBootConfiguration.h"
#import "HTSBootNodeGroup.h"
#import "HTSBootConfigKey.h"

static inline HTSBootNodeList * _parseNodeListFromArray(NSArray * array);

static inline id<HTSBootNode> _parseNodeFromData(NSDictionary *data){
    NSString * type = [data objectForKey:HTS_TASK_TYPE] ?: HTS_TASK_TYPE_NORNAL;
    if ([type isEqualToString:HTS_TASK_TYPE_NORNAL]) {
        return [[HTSBootNode alloc] initWithDictionary:data];
    }else if([type isEqualToString:HTS_TASK_TYPE_GROUP]){
        NSArray * syncData = [data objectForKey:HTS_GROUP_SYNC];
        NSArray * asyncData = [data objectForKey:HTS_GROUP_ASYNC];
        HTSBootNodeList * syncList = _parseNodeListFromArray(syncData);
        HTSBootNodeList * asyncList = _parseNodeListFromArray(asyncData);
        HTSBootNodeGroup * group = [[HTSBootNodeGroup alloc] initWithSyncList:syncList
                                                                    asyncList:asyncList];
        return group;
    }
    return nil;
}

static inline HTSBootNodeList * _parseNodeListFromArray(NSArray * array){
    NSMutableArray * result = [[NSMutableArray alloc] init];
    for (NSDictionary * data in array) {
        id<HTSBootNode> node = _parseNodeFromData(data);
        if (node) {
            [result addObject:node];
        }
    }
    return result;
}

static HTSBootNodeList * _parseNodeListFromDictionary(NSDictionary * dictionary, NSString * key){
    NSArray * dicArr = [dictionary objectForKey:key];
    return _parseNodeListFromArray(dicArr);
}

@interface HTSBootConfiguration()

@property (strong, nonatomic) HTSBootNodeList * foundationList;
@property (strong, nonatomic) HTSBootNodeList * backgroundList;
@property (strong, nonatomic) HTSBootNodeList * firstFourgroundList;
@property (strong, nonatomic) HTSBootNodeList * afterLaunchNowList;
@property (strong, nonatomic) HTSBootNodeList * afterLaunchIdleList;
@property (strong, nonatomic) HTSBootNodeList * feedReadyNowList;
@property (strong, nonatomic) HTSBootNodeList * feedReadyIdleList;

@end

@implementation HTSBootConfiguration

- (instancetype)initWithConfiguration:(NSDictionary *)dic{
    if (self = [super init]) {
        //Parse Launch
        NSDictionary * launchData = [dic objectForKey:HTS_STAGE_LAUNCH];
        self.foundationList = _parseNodeListFromDictionary(launchData,HTS_STAGE_LAUNCH_FOUNDATION);
        self.backgroundList = _parseNodeListFromDictionary(launchData,HTS_STAGE_LAUNCH_FIRST_FOURGROUND);
        self.firstFourgroundList = _parseNodeListFromDictionary(launchData,HTS_STAGE_LAUNCH_FIRST_FOURGROUND);
        //Launch Completion
        NSDictionary * launchCompletionData = [dic objectForKey:HTS_STAGE_LAUNCH_COMPLETIOM];
        self.afterLaunchNowList = _parseNodeListFromDictionary(launchCompletionData,HTS_DELAY_STAGE_NOW);
        self.afterLaunchIdleList = _parseNodeListFromDictionary(launchCompletionData,HTS_DELAY_STAGE_IDLE);
        //FeedReady
        NSDictionary * feedReadyData = [dic objectForKey:HTS_STAGE_FEEDREADY];
        self.feedReadyNowList = _parseNodeListFromDictionary(feedReadyData,HTS_DELAY_STAGE_NOW);
        self.feedReadyIdleList = _parseNodeListFromDictionary(feedReadyData,HTS_DELAY_STAGE_IDLE);
    }
    return self;
}

@end
