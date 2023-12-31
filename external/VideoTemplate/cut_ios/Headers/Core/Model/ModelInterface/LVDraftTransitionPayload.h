//
//  LVDraftTransitionPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import <CoreMedia/CoreMedia.h>
#import "LVDraftPayload.h"
#import "LVMediaDefinition.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVDraftTransitionPayload (Interface)

/**
 转场类型
 */
@property (nonatomic, assign, readonly) LVTransitionType transitionType;

/**
 转场名称
 */
//@property (nonatomic, copy, nonnull) NSString *name;

/**
 转场效果时间
 */
@property (nonatomic, assign) CMTime duration;

/**
 转场 id
 */
//@property (nonatomic, copy, nonnull) NSString *effectID;

/**
 资源唯一标识
 */
//@property (nonatomic, copy, nonnull) NSString *resourceID;

/**
 转场资源路径
 */
//@property (nonatomic, copy, nonnull) NSString *relativePath;

/**
 即转场下发需求之前的 duration
 */
//@property (nonatomic, assign) BOOL isOverlap;

/**
 转场效果时间
 */
@property (nonatomic, assign, readonly) CMTime overlapDuration;

/**
 转场分类名称
 */
//@property (nonatomic, copy, nonnull) NSString *categoryName;

/**
 转场分类 id
 */
//@property (nonatomic, copy, nonnull) NSString *categoryID;

/**
 资源的MD5值
 */
@property (nonatomic, copy) NSString *recourceMD5;
//@property (nonatomic, copy, nonnull) NSString *recourceMD5;

/**
 初始化 None 类型转场实例

 @param type 类型
 @return 实例
 */
+ (instancetype)noneTransitionPayload;

/**
 初始化转场实例
 
 @param type 类型
 @return 实例
 */
- (instancetype)initWithEffectID:(NSString *)effectID
                      effectName:(NSString *)effectName
                        rootPath:(NSString *)rootPath
                            path:(NSString *)path
                       isOverlap:(BOOL)isOverlap;

/**
 转场应用时间
 */
+ (CMTime)transitionApplyDuraion;

/**
 转场效果最小时间限制
 */
+ (CMTime)transitionRequireMinDuration;

@end

NS_ASSUME_NONNULL_END
