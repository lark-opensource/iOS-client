//
//  NLEResourceAV_OC+Extension.h
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import <NLEPlatform/NLEResourceAV+iOS.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NLEInterface_OC;

@interface NLEResourceAV_OC (Extension)

+ (instancetype)videoResourceWithAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle;
+ (instancetype)audioResourceWithAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle;

@end

@interface NLEResourceNode_OC(ResourcePath)

/// 设置私有资源路径，标记资源为私有资源，必要时候需要拷贝到草稿目录中
/// @param url 资源 URL
/// @param draftFolder 草稿目录
- (void)acc_setPrivateResouceWithURL:(NSURL *)url
                         draftFolder:(NSString *)draftFolder;

/// 设置共有资源, effect
/// @param path 资源路径
- (void)acc_setGlobalResouceWithPath:(NSString *)path;

/// 将私有资源迁移到草稿目录中，返回资源是否有移动
- (BOOL)acc_movePrivateResouceToDraftFolder:(NSString *)draftFolder;

- (NSString *)acc_path;

- (BOOL)isRelatedPath:(NSString *)path;

// 草稿目录路径，私有资源才有这个标记
@property (nonatomic, copy) NSString *acc_draftFolder;
// 是否是私有资源
@property (nonatomic, assign, readonly) BOOL acc_isPrivate;

// 重启 APP 沙盒路径可能会修改，需要修复使用绝对路径存草稿的资源
- (void)acc_fixSandboxDirWithDraftFolder:(NSString *)draftFolder;

@end

NS_ASSUME_NONNULL_END
