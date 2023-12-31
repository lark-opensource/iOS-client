//
//  IESLiveResouceBundle+Color.h
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceBundle.h"

/*
 * Color format:
 **  rgb: #d8d8d8
 ** argb: #ffd8d8d8
 
 * reference a exist color
 ** @cinema_text
*/

typedef UIColor * (^IESLiveResouceColor)(NSString *key);
typedef UIColor * (^IESLiveResouceAlphaColor)(NSString *key, CGFloat alpha);

@interface IESLiveResouceBundle (Color)

- (IESLiveResouceColor)color;

- (IESLiveResouceAlphaColor)alphaColor;

- (NSString * (^)(NSString *key))colorName;

@end
