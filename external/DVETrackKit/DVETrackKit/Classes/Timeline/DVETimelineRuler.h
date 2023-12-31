//
//  DVETimelineRuler.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/12.
//

#import <Foundation/Foundation.h>
#import "DVETimelineRulerViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVETimelineRuler : UIView

@property (nonatomic, assign, class, readonly) CGFloat height;

- (instancetype)initWithViewModel:(DVETimelineRulerViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
