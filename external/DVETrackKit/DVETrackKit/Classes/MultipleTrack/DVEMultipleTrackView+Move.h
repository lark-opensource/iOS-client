//
//  DVEMultipleTrackView+Move.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/26.
//

#import "DVEMultipleTrackView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackView (Move)

- (void)setupLongPressGesture;

- (void)updateLongPressSnapCellFrame:(CGRect)updateFrame;

@end

NS_ASSUME_NONNULL_END
