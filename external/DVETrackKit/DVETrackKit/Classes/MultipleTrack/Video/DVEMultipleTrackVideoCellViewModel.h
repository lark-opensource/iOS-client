//
//  DVEMultipleTrackVideoCellViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/27.
//

#import <UIKit/UIKit.h>
#import "DVEMultipleTrackViewCellViewModel.h"
#import "DVEVideoTrackViewModel.h"
#import "DVEVideoThumbnailManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackVideoCellViewModel : DVEMultipleTrackViewCellViewModel

@property (nonatomic, strong, readonly) DVEVideoTrackViewModel *videoTrackViewModel;
@property (nonatomic, strong, readonly) DVEVideoThumbnailManager *thumbnailManager;

- (instancetype)initWithContext:(DVEMediaContext *)context
                        segment:(NLETimeSpaceNode_OC *)segment
                          frame:(CGRect)frame
                backgroundColor:(UIColor *)backgroundColor
                          title:(NSString *)title
                           icon:(NSString *)icon
                      timeScale:(CGFloat)timeScale
                      viewModel:(DVEVideoTrackViewModel *)viewModel
                        manager:(DVEVideoThumbnailManager *)manager;

@end

NS_ASSUME_NONNULL_END
