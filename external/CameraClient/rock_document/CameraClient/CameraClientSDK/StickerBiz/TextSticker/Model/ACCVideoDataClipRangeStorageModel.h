//
//  ACCVideoDataClipRangeStorageModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/17.
//

#import <Mantle/MTLModel.h>
#import "ACCSerializationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCVideoDataClipRangeStorageModel : MTLModel<ACCSerializationProtocol>

/// 开始时间(秒)
@property (nonatomic, assign) CGFloat startSeconds;
/// 持续时间(秒)
@property (nonatomic, assign) CGFloat durationSeconds;
/// 对齐时间，该时间片插入到主时间线中的起始时间，默认0
@property (nonatomic, assign) CGFloat attachSeconds;
/// 资源循环插入次数，默认1
@property (nonatomic, assign) NSInteger repeatCount;
/// 是否是无效视频
@property (nonatomic, assign) BOOL isDisable;

@end

NS_ASSUME_NONNULL_END
