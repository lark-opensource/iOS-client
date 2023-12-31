//
//  NLEEditorCommitProtocol.h
//  NLEPlatform
//
//  Created by bytedance on 2021/5/11.
//

#ifndef NLEEditorCommitProtocol_h
#define NLEEditorCommitProtocol_h

@class NLEEditor_OC, NLEModel_OC;

typedef NS_ENUM(NSInteger, NLEEditorCommitStatus) {
    NLEEditorCommitStatusFailed = -1,   // 操作失败
    NLEEditorCommitStatusSync = 0,      // 不属于耗时操作，同步生效
    NLEEditorCommitStatusAsync = 1,     // 耗时操作，异步生效
};

NS_ASSUME_NONNULL_BEGIN

@protocol NLEEditor_iOSListenerProtocol <NSObject>

@optional

- (void)nleModelChanged:(NLEModel_OC *)model withResultCode:(int)resultCode;

/// 返回状态，标记是否内部调用ve是否为异步的
/// @param editor NLEEditor_OC
/// @param currentModel 是一个存储 commit 前的 stageModel 对象，使用之前需要判断 isStage
- (NLEEditorCommitStatus)editor:(NLEEditor_OC *)editor
          statusForCurrentModel:(nullable NLEModel_OC *)currentModel;

- (void)editor:(NLEEditor_OC *)editor
doRenderWithCurrentModel:(nullable NLEModel_OC *)currentModel
    completion:(nullable void(^)(NSError *renderError))completion;

@end

@protocol NLEEditorCommitContextProtocol <NSObject>

/// 编辑是否需要一部处理渲染动作
@property (nonatomic, assign) NLEEditorCommitStatus status;

/// 每次commit生成的唯一id，ios 侧使用UUID
@property (nonatomic, copy) NSString *identifier;
@end

NS_ASSUME_NONNULL_END

#endif /* NLEEditorCommitProtocol_h */
