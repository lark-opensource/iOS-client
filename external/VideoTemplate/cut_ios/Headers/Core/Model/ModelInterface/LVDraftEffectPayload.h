//
//  LVDraftEffectPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftPayload.h"

NS_ASSUME_NONNULL_BEGIN

/**
 效果应用类型
 
 - LVEffectPayloadApplyTargetTypeMainVideo: 主视频
 - LVEffectPayloadApplyTargetTypeSubVideo: 画中画
 - LVEffectPayloadApplyTargetTypeGlobal: 全局
 */
typedef NS_ENUM(NSUInteger, LVEffectPayloadApplyTargetType) {
    LVEffectPayloadApplyTargetTypeMainVideo,
    LVEffectPayloadApplyTargetTypeSubVideo,
    LVEffectPayloadApplyTargetTypeGlobal,
};


/**
 特效素材（滤镜，美颜，视频特效）解析模型
 */

@interface LVDraftEffectPayload(Interface)

//@interface LVDraftEffectPayload : LVDraftPayload
/**
 内部贴纸或者效果的标识
 */
//@property (nonatomic, copy, nonnull) NSString *effectID;

/**
 资源唯一标识
 */
//@property (nonatomic, copy, nonnull) NSString *resourceID;

/**
 特效名字
 */
//@property (nonatomic, copy, nonnull) NSString *name;

/**
 文件路径，注意：这个路径应该是草稿目录下的相对路径
 */
//@property (nonatomic, copy, nonnull) NSString *relativePath;

/**
 滑杆值
 */
//@property (nonatomic, assign) float value;

/**
 特效分类id
 */
//@property (nonatomic, copy, nullable) NSString *categoryID;

/**
 特效分类名字
 */
//@property (nonatomic, copy, nullable) NSString *categoryName;

/**
 特效时长
 */
// TODO: - 这里有用到吗？ 协议里没有
//@property (nonatomic, assign) CMTime duration;

/**
 资源的MD5值
 */
@property (nonatomic, copy, nullable) NSString *resourceMD5;

/**
应用对象类型
*/
@property (nonatomic, assign) LVEffectPayloadApplyTargetType applyType;

/**
 默认最大值
 */
//+ (CGFloat)maxValue;

/**
 初始化特效
 
 @param type 素材类型
 @param effectID 特效ID
 @param resourceID 特效资源ID
 @param path 特效路径
 @param name 特效名称
 @param platformSupport 平台支持
 @return 特效实例
 */
- (instancetype)initWithType:(LVPayloadRealType)type
                    effectID:(NSString *)effectID
                  resourceID:(NSString *)resourceID
                    rootPath:(NSString *)rootPath
                        path:(NSString *)path
                        name:(NSString *)name
             platformSupport:(LVMutablePayloadPlatformSupport)platformSupport;

/**
 初始化特效
 
 @param type 素材类型
 @param effectID 特效ID
 @param resourceID 特效资源ID
 @param path 特效路径
 @param name 特效名称
 @param platformSupport 平台支持
 @param resourceMD5 资源的MD5值
 @return 特效实例
 */
- (instancetype)initWithType:(LVPayloadRealType)type
                    effectID:(NSString *)effectID
                  resourceID:(NSString *)resourceID
                    rootPath:(NSString *)rootPath
                        path:(NSString *)path
                        name:(NSString *)name
             platformSupport:(LVMutablePayloadPlatformSupport)platformSupport
                 resourceMD5:(NSString * _Nullable)resourceMD5;

/**
 资源绝对路径
 */
- (NSString *)absolutePath;

@end

NS_ASSUME_NONNULL_END
