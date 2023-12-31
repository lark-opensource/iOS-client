//
//  ACCOldFilterUIConfigurationProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/7/28.
//

#import <Foundation/Foundation.h>

@protocol ACCOldFilterUIConfigurationProtocol <NSObject>

/// selected filter border color
- (UIColor *)effectCellSelectedBorderColor;

/// filter slider minimum track tint color
- (UIColor *)sliderMinimumTrackTintColor;

@end
