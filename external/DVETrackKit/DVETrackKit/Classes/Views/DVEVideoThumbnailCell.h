//
//  DVEVideoThumbnailCell.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/27.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEVideoThumbnailCell : UIView

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, copy) NSString *reuseIdentifier;
@property (nonatomic, assign) CMTime time;

@end

NS_ASSUME_NONNULL_END
