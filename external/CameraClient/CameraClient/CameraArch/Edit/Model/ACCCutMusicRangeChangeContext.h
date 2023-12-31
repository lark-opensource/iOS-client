//
//  ACCCutMusicRangeChangeContext.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/1/5.
//

#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import "AWEVideoEditDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCCutMusicRangeChangeContext : NSObject

@property (nonatomic, assign) HTSAudioRange audioRange;
@property (nonatomic, assign) AWEAudioClipRangeChangeType changeType;

+ (instancetype)createWithAudioRange:(HTSAudioRange)range changeType:(AWEAudioClipRangeChangeType)changeType;

@end

NS_ASSUME_NONNULL_END
