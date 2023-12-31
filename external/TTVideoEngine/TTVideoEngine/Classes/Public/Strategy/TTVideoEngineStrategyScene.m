//
//  TTVideoEngineStrategyScene.m
//  TTVideoEngine
//
//  Created by 黄清 on 2021/7/14.
//

#import "TTVideoEngineStrategyScene.h"
#import "NSDictionary+TTVideoEngine.h"


@implementation TTVideoEngineStrategyScene

+ (instancetype)scene:(NSString *)sceneId {
    return [[self alloc] initWithSceneId:sceneId];
}

- (instancetype)initWithSceneId:(NSString *)sceneId {
    if (self = [super init]) {
        _sceneId = sceneId;
    }
    return self;
}

- (NSString *)toJsonString {
    NSMutableDictionary *temDict = [NSMutableDictionary dictionary];
    [temDict setValue:_sceneId forKey:@"scene_id"];
    [temDict setValue:_briefSceneId forKey:@"brief_scene_id"];
    [temDict setObject:@(_autoPlay) forKey:@"auto_play"];
    [temDict setObject:@(_muted) forKey:@"mute"];
    [temDict setObject:@(_maxVisibleCardCnt) forKey:@"card_cnt"];
    [temDict setValue:_configString forKey:@"json"];
    return temDict.ttvideoengine_jsonString;
}

@end
