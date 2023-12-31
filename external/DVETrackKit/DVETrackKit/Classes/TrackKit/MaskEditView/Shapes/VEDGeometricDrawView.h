//
//  VEDGeometricDrawView.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <Foundation/Foundation.h>
#import "VEDMaskDrawView.h"

NS_ASSUME_NONNULL_BEGIN

@class SVGBezierPath;
@interface VEDGeometricDrawView : VEDMaskDrawView

@property (nonatomic, copy) NSArray<SVGBezierPath *> *paths;

@property (nonatomic, strong) UIBezierPath *combinedPath;

+ (CGSize)SVGSizeWithSVGFile:(NSString *)path WithMaxSize:(CGSize)maxSize borderSize:(CGSize)borderSize;

@end

NS_ASSUME_NONNULL_END
