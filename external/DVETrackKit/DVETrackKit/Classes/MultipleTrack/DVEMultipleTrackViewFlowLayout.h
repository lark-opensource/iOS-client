//
//  DVEMultipleTrackViewFlowLayout.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/23.
//

#import <UIKit/UIKit.h>
#import "DVEMultipleTrackViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, strong) DVEMultipleTrackViewModel *viewModel;

- (instancetype)initWithViewModel:(DVEMultipleTrackViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
