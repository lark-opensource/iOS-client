//
//  NLENode+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NLENode_OC;

@protocol NLENodeCallbackProtocol <NSObject>

- (void)nleNodeChanged:(NLENode_OC *)node;

@end

@interface NLENode_OC : NSObject

/// 获取NLENode 的name，这个name在初始化时会固化，深拷贝不会改变
@property (nonatomic, copy) NSString *name;

/// 标识这个NLENode 是否启用，NLE内部diff更新视频总时长时会使用到
@property (nonatomic, assign, getter=isEnable) BOOL enable;

/// NLENode唯一标识，且草稿存盘恢复后保持不变
@property (nonatomic, copy, readonly) NSString *UUID;

/// 兼容老版本保留的接口
- (NSString *)getUUID;

/// 获取业务自己设置的所有额外字段key数组
- (NSMutableArray<NSString*>*)getExtraKeys;

/// 获取保存的额外数据
/// @param key NSString
- (nullable NSString *)getExtraForKey:(NSString *)key;

/// 保存业务的额外数据，参与草稿存盘/恢复
/// @param extra NSString *
/// @param key NSString *
- (void)setExtra:(nullable NSString *)extra forKey:(NSString *)key;

/// 获取保存的额外数据，不存草稿，可以作为关联对象使用
/// @param key NSString
- (nullable NSString *)getTransientExtraForKey:(NSString *)key;

/// 保存业务的额外数据，不存草稿，可以作为关联对象使用
/// @param extra NSString *
/// @param key NSString *
- (void)setTransientExtra:(nullable NSString *)extra forKey:(NSString *)key;

/// 是否有缓存某个额外key的数据
/// @param key NSString *
- (BOOL)hasExtraForKey:(NSString *)key;

/// 添加NLENode 数据变化时的回调
/// @param listener id<NLENodeCallbackProtocol>
- (void)addListener:(id<NLENodeCallbackProtocol>)listener;

/// 移除监听回调
/// @param listener id<NLENodeCallbackProtocol>
- (void)removeListener:(id<NLENodeCallbackProtocol>)listener;

// 为了避免 hash 冲突，后续还是需要替换成真正的 NodeID
- (NSString*)hash;

/// 获取NLENode id，这个id是NLENode实例的内存地址，不推荐使用，深拷贝会改变
- (uint64_t)getID;

/// 获取NLENode 的name，这个name在初始化时会固化，深拷贝不会改
/// 变，和属性name是一样的，为了兼容旧版本，暂时保留
- (NSString *)getName;

/// 深拷贝（不改变id）
- (instancetype)deepClone;

/// 深拷贝（修改name 和 uuid）
/// @param shouldChangeId 是否改变id
- (instancetype)deepClone:(BOOL)shouldChangeId;

- (NSString *)nodeClassName;

- (NSString *)nodeClassName;

@end

NS_ASSUME_NONNULL_END
