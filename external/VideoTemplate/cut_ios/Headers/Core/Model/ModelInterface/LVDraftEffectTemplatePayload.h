//
//  LVDraftEffectTemplatePayload.h
//  Pods
//
//  Created by iRo on 2020/10/9.
//

#import "LVDraftPayload.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVDraftEffectTemplatePayload(Interface)
/**
 初始化模板
 
 @param type 素材类型
 @param effectID 特效ID
 @param resourceID 特效资源ID
 @param path 特效路径
 @param name 特效名称
 @param platformSupport 平台支持
 @return 实例
 */
- (instancetype)initWithType:(LVPayloadRealType)type
                    effectID:(NSString *)effectID
                  resourceID:(NSString *)resourceID
                    rootPath:(NSString *)rootPath
                        path:(NSString *)path
                        name:(NSString *)name
             platformSupport:(LVMutablePayloadPlatformSupport)platformSupport;

/**
 资源绝对路径
 */
- (NSString *)absolutePath;
@end

@interface LVDraftTextTemplatePayload(Interface)

@end

@interface LVEffectTemplateResource(Interface)

/**
初始化模板

@param panel 面板
@param resourceID 特效资源ID
@param path 特效路径
@return 实例
*/
- (instancetype)initWithPanel:(NSString *)panel
                   resourceID:(NSString *)resourceID
                         path:(NSString *)path;


/**
资源绝对路径
*/
- (NSString *)absolutePathWithRootPath:(NSString *)rootPath;

@end

NS_ASSUME_NONNULL_END
