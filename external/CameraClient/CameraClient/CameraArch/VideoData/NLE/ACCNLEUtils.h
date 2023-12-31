//
//  ACCNLEUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/2/18.
//

#import <Foundation/Foundation.h>
@class AWEVideoPublishViewModel,
VEEditorSessionConfig,
ACCNLEEditVideoData,
NLEEditor_OC,
NLEInterface_OC;

typedef NS_ENUM(NSUInteger, ACCCreativePolicy) {
    ACCCreativePolicyNormal = 1,
    ACCCreativePolicyNLE,
};

NS_ASSUME_NONNULL_BEGIN

@interface ACCNLEUtils : NSObject

// 是否使用 NLE 来编辑
+ (BOOL)useNLEWithRepository:(AWEVideoPublishViewModel *)repository;

// NLE AB 逻辑
+ (ACCCreativePolicy)creativePolicyWithRepository:(AWEVideoPublishViewModel *)repository;

// 是否需要创建新的 NLEInterface，如果 VE 配置没变化则不创建新的 NLEInterface
+ (NLEInterface_OC *)createNLEInterfaceIfNeededWithRepository:(AWEVideoPublishViewModel *)repository;

// 根据 NLEEditor 创建 NLE VideoData，草稿恢复是这个逻辑
+ (void)createNLEVideoData:(AWEVideoPublishViewModel *)repository
                    editor:(NLEEditor_OC *)editor
                completion:(nullable void(^)(void))completion;

/// 创建 NLE VideoData 以及 Editor，并且决定是否将资源拷贝到草稿目录中，普通进编辑场景
+ (void)createNLEVideoData:(AWEVideoPublishViewModel *)repository
                    config:(nullable VEEditorSessionConfig *)config
              moveResource:(BOOL)moveResource
                needCommit:(BOOL)needCommit
                completion:(nullable void(^)(void))completion;

// 创建 NLE Editor
+ (NLEInterface_OC *)nleInterfaceWithRepository:(AWEVideoPublishViewModel *)repository;

// 即将开始编辑的逻辑，会做一些数据逻辑的调整
+ (void)repositoryFallbackVEIfNeeded:(AWEVideoPublishViewModel *)repository;

// 持久化 NLEEditor 数据
+ (void)saveNLEEditor:(NLEEditor_OC *)editor
           repository:(AWEVideoPublishViewModel *)repositoty
         businessJSON:(NSString *)businessJSON
           completion:(void (^)(void))completion;

// 保存 NLEEditor 的编辑数据，是saveNLEEditor:repository:businessJSON:completion:中的一个子函数，不存本地草稿
+ (void)syncNLEEditor:(NLEEditor_OC *)editor
           repository:(AWEVideoPublishViewModel *)repository;

// 从草稿加载 NLEEditor
+ (NLEEditor_OC *)loadNLEEditorWithDraftID:(NSString *)draftID
                          publishViewModel:(AWEVideoPublishViewModel *)publishViewModel
                                     error:(NSError **)error;

// 移除 NLEEditor 存储
+ (void)removeNLEEditorWithDraftID:(NSString *)draftId;

// nle 文件名称
@property (nonatomic, copy, class, readonly) NSString *nleFileName;

@end

// 检测容器和编辑数据的 NLE 状态是否匹配
static inline void ACC_CHECK_NLE_COMPATIBILITY(BOOL isNLE, AWEVideoPublishViewModel *publishViewModel)
{
    int containerIsNLE = isNLE ? 1 : 0;
    int publishViewModelIsNLE = [ACCNLEUtils creativePolicyWithRepository:publishViewModel] == ACCCreativePolicyNLE ? 1 : 0;
    if (~(containerIsNLE ^ publishViewModelIsNLE)) {
        assert("container nle engine must be same as publishViewModel nle type");
    }
}

NS_ASSUME_NONNULL_END
