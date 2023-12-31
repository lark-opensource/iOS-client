//
//  DVEVideoTransitionItem.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/17.
//

#import "MeepoButton.h"
#import "DVEVideoTransitionModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEVideoTransitionItem : MeepoButton

@property (nonatomic, strong) DVEVideoTransitionModel *model;

- (instancetype)initWithModel:(DVEVideoTransitionModel *)model;

@end

NS_ASSUME_NONNULL_END
