//
//  ACCResourceBundleProtocol.h
//  CameraClient
//
//  Created by Liu Deping on 2019/11/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCResourceBundleProtocol <NSObject>

- (NSString *)currentResourceBundleName;

- (BOOL)isDarkMode;
// support iOS13 dark mode
- (BOOL)supportDarkMode;

@optional
- (BOOL)isLightMode;

@end

NS_ASSUME_NONNULL_END
