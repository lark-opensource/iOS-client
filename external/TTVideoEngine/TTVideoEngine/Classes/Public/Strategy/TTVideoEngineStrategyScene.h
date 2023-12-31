//
//  TTVideoEngineStrategyScene.h
//  TTVideoEngine
//
//  Created by 黄清 on 2021/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineStrategyScene : NSObject

@property (nonatomic, copy, null_unspecified) NSString *sceneId;
@property (nonatomic, copy, nullable) NSString *briefSceneId;
@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) NSInteger maxVisibleCardCnt;
@property (nonatomic, copy, null_unspecified) NSString *configString;

+ (instancetype)scene:(NSString *)sceneId;
- (instancetype)initWithSceneId:(NSString *)sceneId;

- (NSString *)toJsonString;

@end

NS_ASSUME_NONNULL_END
