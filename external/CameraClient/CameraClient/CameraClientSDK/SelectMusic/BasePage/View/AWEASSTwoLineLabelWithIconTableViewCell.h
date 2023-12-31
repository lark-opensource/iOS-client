//
//  AWEASSTwoLineLabelWithIconTableViewCell.h
//  AWEStudio
//
//  Created by liunan on 2018/11/26.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEASSTwoLineLabelWithIconTableViewCell : UITableViewCell
@property (nonatomic, strong, readonly) UIImageView *icon;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@end

NS_ASSUME_NONNULL_END
