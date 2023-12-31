//
//  DouyinOpenSDKPhoneAuthTableViewCell.h
//  Pods
//
//  Created by bytedance on 2022/5/12.
//


#import <UIKit/UIKit.h>

@interface DouyinOpenSDKPhoneAuthTableViewCell: UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel *permissionLabel;
@property (nonatomic, strong) IBOutlet UIImageView *iconImageView;
- (CGFloat)heightForText:(NSString *)text topMargin:(CGFloat)topMargin width:(CGFloat)width;
@end
