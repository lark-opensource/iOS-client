//
//  ACCLocalAudioManageSection.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCLocalAudioManageSection : UITableViewCell

+ (CGFloat)sectionHeight;

@property (nonatomic, copy) dispatch_block_t clickAction;

- (void)configWithEditStatus:(BOOL)isEdit;

@end

NS_ASSUME_NONNULL_END
