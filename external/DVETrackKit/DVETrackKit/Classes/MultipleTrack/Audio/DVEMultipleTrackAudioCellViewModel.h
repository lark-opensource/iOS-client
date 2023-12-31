//
//  DVEMultipleTrackAudioCellViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/29.
//

#import <Foundation/Foundation.h>
#import "DVEMultipleTrackViewCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEAudioWaveViewModel;
@interface DVEMultipleTrackAudioCellViewModel : DVEMultipleTrackViewCellViewModel

@property (nonatomic, strong) DVEAudioWaveViewModel *audioWaveViewModel;
@property (nonatomic, copy, nullable) NSString *iconTitle;


- (instancetype)initWithContext:(DVEMediaContext *)context
                        segment:(NLETimeSpaceNode_OC * _Nullable)segment
                          frame:(CGRect)frame
                backgroundColor:(UIColor *)backgroundColor
                          title:(NSString * _Nullable)title
                           icon:(NSString * _Nullable)icon
                      iconTitle:(NSString * _Nullable)iconTitle
                      timeScale:(CGFloat)timeScale
             audioWaveViewModel:(DVEAudioWaveViewModel *)audioWaveViewModel;

@end

NS_ASSUME_NONNULL_END
