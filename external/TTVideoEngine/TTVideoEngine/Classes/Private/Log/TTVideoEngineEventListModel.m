//
//  TTVideoEngineEventListModel.m
//  TTVideoEngine
//
//  Created by bytedance on 2021/6/16.
//

#import "TTVideoEngineEventListModel.h"

@interface TTVideoEngineEventListModel () {
    NSMutableArray *_eventModelArr;
    NSLock *_lock;
}

@end


@implementation TTVideoEngineEventListModel

- (instancetype)init {
    if (self = [super init]) {
        _lock = [[NSLock alloc] init];
        _eventModelArr = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addEventModel:(id)eventModel {
    if (!eventModel) {
        return;
    }
    
    [_lock lock];
    
    if (_eventModelArr.count < 100) {
        [_eventModelArr addObject:eventModel];
    }
    
    [_lock unlock];
}

- (NSArray *)eventModels {
    NSArray *tempArr = nil;
    
    [_lock lock];
    
    tempArr = [_eventModelArr copy];
    
    [_lock unlock];
    
    return tempArr;
}

@end


