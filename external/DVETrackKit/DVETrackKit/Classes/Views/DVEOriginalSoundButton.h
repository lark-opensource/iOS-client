//
//  DVEOriginalSoundButton.h
//  DVETrackKit
//
//  Created by bytedance on 2021/6/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DVEMediaContext;

@interface DVEOriginalSoundButton : UIView

- (instancetype)initWithContext:(DVEMediaContext *)context;

- (void)setSelected:(BOOL)isSelected;

@end

NS_ASSUME_NONNULL_END
