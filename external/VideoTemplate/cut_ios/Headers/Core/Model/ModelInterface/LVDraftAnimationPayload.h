//
//  LVDraftAnimationPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftPayload.h"

NS_ASSUME_NONNULL_BEGIN


typedef enum : NSUInteger {
    LVAnimationTypeIn = 1,
    LVAnimationTypeOut,
    LVAnimationTypeLoop,
} LVAnimationType;

@interface LVAnimationInfo(Interface)<LVCopying>
/**
 动画ID
 */
@property (nonatomic, copy) NSString *animationID;

/**
 资源唯一标识
 */
//@property (nonatomic, copy, nonnull) NSString *resourceID;

/**
 动画类型
 */
@property (nonatomic, copy) NSString *animationType;

/**
 动画时长 ms
 */
//@property (nonatomic, assign) long duration;

/**
 动画资源的相对路径
 */
//@property (nonatomic, copy) NSString *relativePath;

/**
 动画资源的根目录
 */
//@property (nonatomic, copy) NSString *rootPath;

/**
 动画名称
 */
//@property (nonatomic, copy) NSString *animationName;

/**
 资源支持的平台
 */
@property (nonatomic, assign) LVMutablePayloadPlatformSupport platformSupport;

/**
 资源的MD5
 */
@property (nonatomic, copy, nullable) NSString *resourceMD5;

@end

@interface LVDraftAnimationPayload(Interface)<LVCopying>

/**
 动画的数组
 */
//@property (nonatomic, copy, nonnull) NSArray<LVAnimationInfo *> *animations;

@end

NS_ASSUME_NONNULL_END
