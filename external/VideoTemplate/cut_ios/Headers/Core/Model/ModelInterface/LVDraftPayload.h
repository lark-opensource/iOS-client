//
//  LVDraftPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LVModelType.h"
#import "LVMediaDefinition.h"
#import "LVGenerateID.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

//@interface LVDraftPayload : MTLModel <MTLJSONSerializing, LVCopying>

@interface LVDraftPayload(Interface)<LVCopying>
/*
 @property (nonatomic, copy)   NSString *identifier;
 @property (nonatomic, assign) LVPlatformEnum platform;
 @property (nonatomic, copy)   NSString *type;
 */
/**
 资源ID
 */
@property (nonatomic, copy) NSString *payloadID;

/**
 资源具体类型
 */
@property (nonatomic, assign) LVPayloadRealType realType;

/**
 资源类目类型
 */
@property (nonatomic, assign, readonly) LVPayloadGenericType genericType;

/**
 文件根目录
 */
@property (nonatomic, copy, nonnull) NSString *rootPath;

/**
 时长
 */
@property (nonatomic, assign) CMTime duration;

/**
 资源是否可替换
 */
@property (nonatomic, assign) Boolean canReplace;

/**
 资源支持的平台
 */
@property (nonatomic, assign) LVMutablePayloadPlatformSupport platformSupport;

/**
 可替换的相同视频素材的轨道标记,  以 v0, v1, v2... 递增
 */
@property (nonatomic, assign, nullable) NSString *relationVideoGroup;

/**
 初始化素材资源
 
 @param type 类型
 @return 资源实例
 */
- (instancetype)initWithType:(LVPayloadRealType)type;

/**
 初始化素材资源
 
 @param type 类型
 @param payloadID 唯一标识
 @return 资源实例
 */
- (instancetype)initWithType:(LVPayloadRealType)type payloadID:(NSString * _Nullable)payloadID;

@end

NS_ASSUME_NONNULL_END
