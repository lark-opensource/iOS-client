//
//  LVMediaDraft.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LVDraftConfig.h"
#import "LVPlatform.h"
#import "LVCanvasConfig.h"
#import "LVMediaTrack.h"
#import "LVPayloadPool.h"
#import "LVMutableConfig.h"
#import "LVDraftVideoPayload.h"
#import "LVDraftAudioPayload.h"
#import "LVDraftTransitionPayload.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

//@interface LVMediaDraft : MTLModel <MTLJSONSerializing, LVCopying>

@interface LVMediaDraft (Interface)<LVCopying>

/*
 @interface LVMediaDraft : NSObject
 @property (nonatomic, nullable, strong) LVDraftPayload *aaaneverUse;
 @property (nonatomic, strong)           LVCanvasConfig *canvasConfig;
 @property (nonatomic, strong)           LVDraftConfig *config;
 @property (nonatomic, assign)           NSInteger createAt;
 @property (nonatomic, assign)           NSInteger durationMilliSeconds;
 @property (nonatomic, copy)             NSString *draftID;
 @property (nonatomic, strong)           LVPayloadPool *payloadPool;
 @property (nonatomic, nullable, strong) LVMutableConfig *mutableConfig;
 @property (nonatomic, copy)             NSString *name;
 @property (nonatomic, copy)             NSString *draftVersion;
 @property (nonatomic, strong)           LVPlatform *platform;
 @property (nonatomic, copy)             NSArray<LVMediaTrack *> *tracks;
 @property (nonatomic, assign)           NSInteger updateAt;
 @property (nonatomic, assign)           NSInteger version;
 @property (nonatomic, copy)             NSString *workspace;
 @end
 */
///**
// 草稿ID
// */
//@property (nonatomic, copy) NSString *draftID;
//
///**
// 草稿版本号
// */
//@property (nonatomic, assign) NSInteger version;
//
///**
// 草稿新版本号
// */
//@property (nonatomic, copy) NSString *draftVersion;
//
///**
// 草稿名字
// */
//@property (nonatomic, copy) NSString *name;

/**
 草稿的时长
 */
@property (nonatomic, assign, readonly) CMTime duration;

/**
// 草稿创建时间
// */
//@property (nonatomic, assign) NSTimeInterval createAt;
//
///**
// 草稿刷新时间
// */
//@property (nonatomic, assign) NSTimeInterval updateAt;
//
///**
// 草稿全局配置
// */
//@property (nonatomic, strong) LVDraftConfig *config;
//
///**
// 草稿画布信息
// */
//@property (nonatomic, strong) LVCanvasConfig *canvasConfig;

///**
// 草稿包含的轨道
// */
//@property (nonatomic, copy) NSArray<LVMediaTrack*>*tracks;

///**
// 设备信息 app版本
// */
//@property (nonatomic, strong) LVPlatform *platform;

///**
// 模板可替换资源
// */
@property (nonatomic, strong) LVMutableConfig *mutableConfig;

///**
// 资源列表
// */
//@property (nonatomic, strong) LVPayloadPool *payloadPool;

/**
 对齐画布/视频
 */
@property (nonatomic, assign) LVMutableConfigAlignMode alignMode;

/**
 初始化一个空的草稿模型
 
 @param draftID 草稿ID
 @return 草稿模型
 */
- (instancetype)initWithDraftID:(NSString *)draftID;

/**
 初始化草稿模型
 
 @param payloads 主素材列表
 @param draftID 草稿ID
 @return 草稿模型
 */
- (instancetype)initWithPayloads:(NSArray<LVDraftVideoPayload *> *)payloads
                         draftID:(NSString *)draftID;

/**
初始化草稿模型

@param payloads 主素材列表
@param sourceTimeRanges 素材范围
@param draftID 草稿ID
@return 草稿模型
*/
- (instancetype)initWithPayloads:(NSArray<LVDraftVideoPayload *> *)payloads
                sourceTimeRanges:(NSArray<NSValue *> *)sourceTimeRanges
                         draftID:(NSString *)draftID;

/**
 更新画布尺寸
 */
- (void)updateOriginRatio;

/**
 强制更新画布原始比例
 */
- (void)forceUpdateOriginRatio;

/**
 默认草稿版本
 
 @return 默认版本
 */
+ (NSInteger)defaultVersion;

@end

NS_ASSUME_NONNULL_END
