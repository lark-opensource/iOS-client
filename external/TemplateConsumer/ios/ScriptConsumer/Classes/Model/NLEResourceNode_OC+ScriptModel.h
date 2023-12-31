//
//   NLEResourceNode_OC+ScriptModel.h
//   TemplateConsumer
//
//   Created  by ByteDance on 2021/6/26.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import <NLEPlatform/NLEResourceNode+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEResourceNode_OC (ScriptModel)


/// NLEResourceNode添加额外字段，最终会留在NLEResourceNode
/// @param value  value
/// @param key key
-(void)setExtraForNode:(NSString*)value forKey:(NSString*)key;

/// NLEResourceNode添加额外字段，最终会插入依附的NLESegment
/// @param value  value
/// @param key key
-(void)setExtraForSegement:(NSString*)value forKey:(NSString*)key;

/// NLEResourceNode添加额外字段，最终会插入依附的NLESlot
/// @param value  value
/// @param key key
-(void)setExtraForSlot:(NSString*)value forKey:(NSString*)key;


/// NLEResourceNode添加额外字段，最终会留在NLEResourceNode
/// @param config 字典类型
-(void)setExtraForNode:(NSDictionary*)config;

/// NLEResourceNode添加额外字段，最终会插入依附的NLESegment
/// @param config 字典类型
-(void)setExtraForSegement:(NSDictionary*)config;

/// NLEResourceNode添加额外字段，最终会插入依附的NLESlot
/// @param config 字典类型
-(void)setExtraForSlot:(NSDictionary*)config;

@end

NS_ASSUME_NONNULL_END
