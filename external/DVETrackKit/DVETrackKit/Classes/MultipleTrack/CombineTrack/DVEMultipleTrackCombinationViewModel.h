//
//  DVEMultipleTrackCombinationViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/29.
//

#import <Foundation/Foundation.h>
#import "DVEMultipleTrackViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackCombinationViewModel : DVEMultipleTrackViewModel

@property (nonatomic, copy) NSArray<DVEMultipleTrackViewModel *> *mixViewModels;

@end

NS_ASSUME_NONNULL_END
