//
//  VEEditorSession+NLE.h
//  NLEPlatform-Pods-Aweme
//
//  Created by zhangyuanming on 2021/7/28.
//

#import <TTVideoEditor/VEEditorSession.h>

NS_ASSUME_NONNULL_BEGIN

@interface VEEditorSession (NLE)

/// 标识VE是否正在调用restartReverseAsset 进行时光倒流，还没有结束。
/// 防止重复调用
@property (nonatomic, assign) BOOL nle_isReversingAssets;

@end

NS_ASSUME_NONNULL_END
