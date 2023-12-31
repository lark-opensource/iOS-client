//
//  AWEStickerPickerSearchBarConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/31.
//

#import <Foundation/Foundation.h>

#if __has_feature(modules)
@import UIKit;
#else
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerPickerSearchBarConfig : NSObject

+ (instancetype)sharedConfig;

@property (nonatomic, strong, nullable) UIColor *backgroundColor;
@property (nonatomic, strong, nullable) UIColor *textColor;
@property (nonatomic, strong, nullable) UIColor *tintColor;
@property (nonatomic, strong, nullable) UIColor *searchFiledBackgroundColor;
@property (nonatomic, strong, nullable) UIImage *lensImage;
@property (nonatomic, strong, nullable) UIImage *clearImage;
@property (nonatomic, assign) CGFloat searchBarHeight;
@property (nonatomic, strong, nullable) UIColor *lensImageTintColor;

@end

NS_ASSUME_NONNULL_END
