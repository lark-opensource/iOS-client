//
//  DVEAudioFadeInOutView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/6/30.
//

#import <UIKit/UIKit.h>

@class DVEMultipleTrackViewCellViewModel;

typedef NS_ENUM(NSUInteger, DVEAudioFadeInOutViewType){
    DVEAudioFadeInOutViewTypeNONE = 0,       // 空/未知/占位
    DVEAudioFadeInOutViewTypeIn = 1,
    DVEAudioFadeInOutViewTypeOut = 2,
    
};

NS_ASSUME_NONNULL_BEGIN

@interface DVEAudioFadeInOutView : UIView

- (instancetype)initWithWaveModel:(DVEMultipleTrackViewCellViewModel * _Nullable)waveModel Type:(DVEAudioFadeInOutViewType)viewType;



@end

NS_ASSUME_NONNULL_END
