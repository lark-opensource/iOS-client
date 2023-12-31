//
//  ACCNLEEditVideoData.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/11.
//

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@class NLEModel_OC, NLEInterface_OC, NLETrackSlot_OC;

/// NLE 侧的资源处理，这里应该是一个 NLEModel
@interface ACCNLEEditVideoData : NSObject<ACCEditVideoDataProtocol>

@property (nonatomic, strong, readonly) NLEModel_OC *nleModel;
@property (nonatomic, strong) NLEInterface_OC *nle;
@property (nonatomic, strong, readonly) HTSVideoData *videoData;

// 贴纸 id 变化 map，key 是老的贴纸 id，value 是对应贴纸的 slotName
@property (nonatomic, copy, nullable) NSDictionary<NSNumber *, NSString *> *stickerChangeMap;

// 是否是临时 VideoData，临时 VideoData 会在编辑页重建，
// 使用此变量来防止重复创建 NLEEditor 可能造成的性能损耗
@property (nonatomic, assign) BOOL isTempVideoData;

- (instancetype)initWithNLEModel:(NLEModel_OC *)nleModel
                             nle:(NLEInterface_OC *)nle;
- (instancetype)init NS_UNAVAILABLE;

- (NLETrackSlot_OC *)addPictureWithURL:(NSURL *)url duration:(CGFloat)duration;

// ACCNLEEditVideoData 的 nle 实例的当前编辑对象可能会被设置为其他的 nleModel，
// 此方法的目的是设置回为当前 model 并且重新设置 nle 的代理信息
- (void)beginEdit;

// 必要的时候将资源迁移到草稿目录，返回值代表是否有迁移
- (BOOL)moveResourceToDraftFolder:(NSString *)draftFolder;

// 剪裁音乐时长，防止超过主轨
- (void)acc_fixAudioClipRange;

// 下次 commit 的时候需要 update
- (void)pushUpdateType:(VEVideoDataUpdateType)updateType;

@end

NS_ASSUME_NONNULL_END
