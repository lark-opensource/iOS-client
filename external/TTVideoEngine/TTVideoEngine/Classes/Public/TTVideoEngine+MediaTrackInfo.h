//
//  TTVideoEngine+MediaTrackInfo.h
//  TTVideoEngine
//
//  Created by zhangxin on 2022/5/12.
//

#import "TTVideoEngine.h"

NS_ASSUME_NONNULL_BEGIN

//mediatrackinfo model json field name
FOUNDATION_EXTERN NSString *const kTTVideoEngineMediaTrackInfoModelIndexKey;
FOUNDATION_EXTERN NSString *const kTTVideoEngineMediaTrackInfoModelTypeKey;
FOUNDATION_EXTERN NSString *const kTTVideoEngineMediaTrackInfoModelLanguageKey;
FOUNDATION_EXTERN NSString *const kTTVideoEngineMediaTrackInfoModelNameKey;
FOUNDATION_EXTERN NSString *const kTTVideoEngineMediaTrackInfoModelGroupIdKey;

@protocol TTVideoEngineMediaTrackInfoProtocol <NSObject>

//required
/* json field name: "index" */
@property (nonatomic, assign, readonly) NSInteger index;
/* json field name: "type" */
@property (nonatomic, assign, readonly) NSInteger type;

- (NSDictionary *_Nullable)toDictionary;

@end

@interface TTVideoEngineMediaTrackInfoModel : NSObject <TTVideoEngineMediaTrackInfoProtocol>

//optional
@property (nonatomic, copy, readonly) NSString *language;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *groupId;

- (instancetype)initWithDictionary:(NSDictionary * _Nonnull)dict;
- (NSDictionary *_Nullable)toDictionary;

@end

@interface TTVideoEngine()

@end

@interface TTVideoEngine(MediaTrackInfo)

/* mediatrackinfo infos from video model*/
- (NSArray<TTVideoEngineMediaTrackInfoModel *> *)getMediaTrackInfos;

@end

NS_ASSUME_NONNULL_END
