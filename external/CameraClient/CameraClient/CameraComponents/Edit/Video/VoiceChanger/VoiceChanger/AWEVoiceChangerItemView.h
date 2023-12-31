//
//  AWEVoiceChangerItemView.h
//  Pods
//
//  Created by chengfei xiao on 2019/5/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEVoiceChangerItemView : UIButton

- (void)setSelected:(BOOL)selected;
- (void)setThumbnailURLList:(NSArray *)thumbnailURLList;
- (void)setCoverBackgroundColor:(UIColor *)backgroundColor;
- (void)setThumbnailURLList:(NSArray *)thumbnailURLList placeholder:(nullable UIImage *)placeholder;

- (void)setCenterImage:(UIImage *)img size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END


