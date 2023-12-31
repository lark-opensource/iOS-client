//
//  NLEExportSession.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/4/27.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/IVEEffectProcess.h>

@class VECompileSession, IESMMTransProcessData;

NS_ASSUME_NONNULL_BEGIN

typedef void(^NLEExportBaseBlock)(void);

@interface NLEExportSession : NSObject

// 需要通过NLEInterface_OC的 - (NLEExportSession *)exportSession; 获取该对象
- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief 获取compileSession
 * @param config 转码配置
 * @param effectUnit 是否需要特效处理节点，多段场景传nil；可通过effectProcess获取
 */
- (void)setupTranscodeConfig:(IESMMTransProcessData *)config
                  effectUnit:(nullable id<IVEEffectProcess>)effectUnit;

@property (nonatomic, copy) void (^_Nullable progressBlock)(CGFloat progress);

- (void)transcodeWithCompleteBlock:(nullable void (^)(IESMMTranscodeRes *_Nullable result))completeBlock;

- (void)cancel:(void (^_Nullable)(void))completion;

- (void)cancelTranscode;

- (id<IVEEffectProcess>)effectProcess;

/**
 * @brief 重新触发倒放操作，使用这个方法会将上一个任务cancel【MV目前不支持倒放】
 * 获取倒放视频路径
 */
- (void)restartReverseAsset:(void (^)(BOOL success, AVAsset * _Nullable reverseAsset, NSError * _Nullable error))completion;

/**
 * @brief 使用当前编辑器配置导出多段倒放片段
 * 使用这个方法可以通过timeMachine获取倒放视频
 */
- (void)restartCurrentEditorReverseAsset:(void (^)(BOOL success, AVAsset * _Nullable reverseAsset, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
