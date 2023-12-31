//
//  ACCUIDynamicColor.m
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/9/15.
//

#import "ACCUIDynamicColor.h"
#import "ACCMacros.h"
#import "ACCServiceLocator.h"


@interface ACCUIDynamicColor ()

@property (nonatomic, copy) UIColor * (^resolveBlock)(ACCUIThemeStyle currentThemeStyle);
@property (nonatomic, strong) UIColor *currentResolvedColor;

@end

@implementation ACCUIDynamicColor

+ (instancetype)dynamicColorWithResolveBlock:(UIColor * (^)(ACCUIThemeStyle currentThemeStyle))resolveBlock
{
    ACCUIDynamicColor *color = [[ACCUIDynamicColor alloc] init];
    color.resolveBlock = resolveBlock;
    [color invalidateCurrentColor];
    [[ACCUIThemeManager sharedInstance] addSubscriber:color];
    return color;
}

#pragma mark - ACCThemeChangeSubscriber
- (void)onThemeChange
{
    [self invalidateCurrentColor];
}

#pragma mark - private
- (void)invalidateCurrentColor
{
    self.currentResolvedColor = self.resolveBlock([ACCUIThemeManager sharedInstance].currentThemeStyle);
}

#pragma mark - UIColor
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.currentResolvedColor;
}

- (CGColorRef)CGColor
{
    return self.currentResolvedColor.CGColor;
}

- (void)set {
    [self.currentResolvedColor set];
}

- (void)setFill {
    [self.currentResolvedColor setFill];
}

- (void)setStroke {
    [self.currentResolvedColor setStroke];
}

- (BOOL)getWhite:(CGFloat *)white alpha:(CGFloat *)alpha {
    return [self.currentResolvedColor getWhite:white alpha:alpha];
}

- (BOOL)getHue:(CGFloat *)hue saturation:(CGFloat *)saturation brightness:(CGFloat *)brightness alpha:(CGFloat *)alpha {
    return [self.currentResolvedColor getHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

- (BOOL)getRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha {
    return [self.currentResolvedColor getRed:red green:green blue:blue alpha:alpha];
}

- (UIColor *)colorWithAlphaComponent:(CGFloat)alpha {
    @weakify(self);
    return [ACCUIDynamicColor dynamicColorWithResolveBlock:^(ACCUIThemeStyle currentThemeStyle){
        @strongify(self);
        return [self.resolveBlock(currentThemeStyle) colorWithAlphaComponent:alpha];
    }];
}

- (id)copyWithZone:(NSZone *)zone {
    ACCUIDynamicColor *color = [[self class] allocWithZone:zone];
    color.resolveBlock = self.resolveBlock;
    color.currentResolvedColor = self.currentResolvedColor;
    return color;
}

- (BOOL)isEqual:(id)object {
    return self == object;
}

- (NSUInteger)hash {
    return (NSUInteger)self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, currentResolvedColor = %@", [super description], self.currentResolvedColor];
}

- (BOOL)_isDynamic {
    return true;
}

- (UIColor *)_highContrastDynamicColor {
    return self;
}

@end
