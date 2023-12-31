//
//  LVDraftBeatsPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftPayload.h"
#import "LVMediaDefinition.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LVBeatsLevel) {
    LVBeatsLevel0 = 0, /// 踩点档位0
    LVBeatsLevel1, /// 踩点档位1
};

typedef NS_ENUM(NSUInteger, LVBeatsMode) {
    LVBeatsMelody = 0, /// 踩旋律
    LVBeatsBeat, /// 踩节拍
};

@interface LVBeatsPoint : NSObject
/**
 开始点
 */
@property (nonatomic, assign) NSInteger threshold;

/**
 时间
 */
@property (nonatomic, assign) CMTime time;

/**
 初始化点
 
 @param threshold 开始点
 @param time 时间
 @return 点
 */
- (instancetype)initWithThreshold:(NSInteger)threshold time:(CMTime)time;

@end

@interface LVDeleteBeats(Interface)
@property (nonatomic, copy) NSArray<NSNumber *> *beat0;
@property (nonatomic, copy) NSArray<NSNumber *> *beat1;
@property (nonatomic, copy) NSArray<NSNumber *> *melody0;
@end

/**
 踩点素材
 */
@interface LVDraftBeatsPayload (Interface)<LVCopying>

///**
// 是否启用了自动踩点
// */
//@property (nonatomic, assign) BOOL enableAiBeats;

/**
 自动踩点档位
 */
@property (nonatomic, assign) LVBeatsLevel level;

/**
 自动踩点类型(0: 踩旋律 1: 踩节拍)
 */
@property (nonatomic, assign) LVBeatsMode mode;

///**
// 服务端踩点信息描述
// */
//@property (nonatomic, strong, nullable) LVAIBeats *aiBeats;

///**
// 用户删除的自动踩点
// */
@property (nonatomic, strong) LVDeleteBeats *userDeleteAIBeats;

/**
 用户踩点的时间点数组
 */
@property (nonatomic, strong) NSArray<LVBeatsPoint *> *userPoints;

/**
 自动踩点的时间点数组
 */
@property (nonatomic, strong) NSArray<LVBeatsPoint *> *aiPoints;

/**
 初始化方法
 
 @param payloadID payloadID
 @return LVDraftBeatsPayload
 */
- (instancetype)initWitPayloadID:(NSString *)payloadID;

/**
 解析json
 
 @param dict json
 @return NSArray<LVDraftBeatsPoint *>
 */
+ (NSArray<LVBeatsPoint *> * _Nullable)convertPointsWithDict:(NSDictionary *)dict;

/**
 过滤自动踩点
 
 @param aiPoints 自动踩点
 @return NSArray<LVDraftBeatsPoint *>
 */
- (NSArray<LVBeatsPoint *> *)selectedAIPoints:(NSArray<LVBeatsPoint *> *)aiPoints;

@end

NS_ASSUME_NONNULL_END
