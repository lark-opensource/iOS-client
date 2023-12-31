//
//  DVEMultipleTrackFilterViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/5/11.
//

#import "DVEMultipleTrackViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackFilterViewModel : DVEMultipleTrackViewModel

- (instancetype)initWithContext:(DVEMediaContext *)context
                  resourceTypes:(NSArray<NSNumber *> *)resourceTypes;

@end

NS_ASSUME_NONNULL_END
