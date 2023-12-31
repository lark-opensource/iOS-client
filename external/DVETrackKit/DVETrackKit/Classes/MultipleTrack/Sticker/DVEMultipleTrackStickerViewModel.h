//
//  DVEMultipleTrackStickerViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/27.
//

#import <UIKit/UIKit.h>
#import "DVEMultipleTrackViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackStickerViewModel : DVEMultipleTrackViewModel

- (instancetype)initWithContext:(DVEMediaContext *)context
                  resourceTypes:(NSArray<NSNumber *> *)resourceTypes;

@end

NS_ASSUME_NONNULL_END
