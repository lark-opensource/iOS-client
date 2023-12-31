//
//  ACCFlowerRewardModel.h
//  Indexer
//
//  Created by xiafeiyu on 11/15/21.
//

#import <CreationKitInfra/ACCBaseApiModel.h>
#import "ACCFlowerCampaignDefine.h"

@interface ACCFlowerRewardRequest : NSObject

/// 用于服务端请求data
@property (nonatomic, copy) NSString *_Nonnull enterFrom;

/// 场景，用于映射获取schema
@property (nonatomic, copy) ACCFLOSceneName _Nonnull schemaScene;

/// 道具id，对应预约期的3款+活动期的道具池
@property (nonatomic, copy) NSString *_Nullable stickerId;

/// 扫码关注场景使用，被关注人uid
@property (nonatomic, copy) NSString *_Nullable followUid;

+ (instancetype)requestWithEnterFrom:(NSString *_Nonnull)enterFrom
                         schemaScene:(ACCFLOSceneName)schemaScene
                           stickerId:(NSString *_Nullable)stickerId;

+ (instancetype)requestWithEnterFrom:(NSString *_Nonnull)enterFrom
                         schemaScene:(ACCFLOSceneName)schemaScene
                           stickerId:(NSString *_Nullable)stickerId
                           followUid:(NSString *_Nullable)followUid;

- (NSDictionary *)toParams;

@end

@interface ACCFlowerRewardResponse : ACCBaseApiModel

@property (nonatomic, copy) NSDictionary *_Nullable data;

@end
