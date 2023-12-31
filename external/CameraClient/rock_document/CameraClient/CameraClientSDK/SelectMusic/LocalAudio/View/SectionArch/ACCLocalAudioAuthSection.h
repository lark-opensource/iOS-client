//
//  ACCLocalAudioAuthSection.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCLocalAudioAuthSection : UITableViewCell

+ (CGFloat)sectionHeight;

@property (nonatomic, copy) dispatch_block_t clickAction;

@end

NS_ASSUME_NONNULL_END
