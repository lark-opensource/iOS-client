//
//  ACCEditPageStrokeConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/5/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditPageStrokeConfig : NSObject

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGLineJoin lineJoin;

+ (instancetype)strokeWithWidth:(CGFloat)width color:(UIColor *)color lineJoin:(CGLineJoin)lineJoin;
 
@end

NS_ASSUME_NONNULL_END
