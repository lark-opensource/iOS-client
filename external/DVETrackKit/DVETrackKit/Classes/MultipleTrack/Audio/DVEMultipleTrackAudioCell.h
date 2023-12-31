//
//  DVEMultipleTrackAudioCell.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/29.
//

#import <Foundation/Foundation.h>
#import "DVEMultipleTrackViewCell.h"
#import "DVEAudioWaveView.h"
#import "DVEAudioSegmentTag.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackAudioCell : DVEMultipleTrackViewCell

@property (nonatomic, strong) DVEAudioWaveView *waveView;

@end

NS_ASSUME_NONNULL_END
