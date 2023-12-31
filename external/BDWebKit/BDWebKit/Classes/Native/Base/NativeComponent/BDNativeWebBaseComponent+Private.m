//
//  BDNativeWebBaseComponent+Private.m
//  BDNativeWebComponent
//
//  Created by liuyunxuan on 2019/9/9.
//

#import "BDNativeWebBaseComponent+Private.h"
#import "NSDictionary+BDNativeWebHelper.h"
#import "NSDictionary+BDNativeWebHelper.h"
#import "NSString+BDNativeWebHelper.h"

@implementation BDNativeWebBaseComponent (Private)

- (void)containerFrameChanged:(BDNativeWebContainerObject *)containerObject
{
    containerObject.nativeView.frame = containerObject.containerView.bounds;
    if (self.radiusNums.count > 1)
    {
        [self handleRadiusByRadiusNums:self.radiusNums view:containerObject.containerView];
    }
}

- (void)baseInsertInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params
{
    [self handleBorderRadiusWithObject:containerObject params:params];
}

- (void)baseUpdateInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params
{
    [self handleBorderRadiusWithObject:containerObject params:params];
}

- (void)baseDeleteInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params
{
    
}

#pragma mark - common handle
- (void)handleBorderRadiusWithObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params
{
    NSString *borderRadius = [params bdNative_stringValueForKey:@"borderRadius"];
    if (borderRadius == nil) {
        return;
    }
    if ([borderRadius isEqualToString:@"null"])
    {
        containerObject.containerView.layer.cornerRadius = 0;
        containerObject.containerView.layer.masksToBounds = NO;
    }
    else if ([borderRadius containsString:@"px"])
    {
        NSArray <NSString *>*strArray = [borderRadius bdNative_nativeDivisionKeywords];
        self.radiusNums = [self getRadiusNumsByStrs:strArray];
        [self handleRadiusByRadiusNums:self.radiusNums view:containerObject.containerView];
        
        return;
    }
}


#pragma mark - private method
- (void)handleRadiusByRadiusNums:(NSArray <NSNumber *>*)radiusNums view:(UIView *)containerView
{
    if (radiusNums.count == 1)
    {
        containerView.layer.mask = nil;
        containerView.layer.masksToBounds = YES;
        containerView.layer.cornerRadius = [[radiusNums objectAtIndex:0] floatValue];
    }
    else if (radiusNums.count == 2)
    {
        containerView.layer.cornerRadius = 0;
        CGFloat borderRadiusNum0 = [[radiusNums objectAtIndex:0] floatValue];
        CGFloat borderRadiusNum1 = [[radiusNums objectAtIndex:1] floatValue];
        
        [self radiusView:containerView
                 topLeft:borderRadiusNum0
                topRight:borderRadiusNum1
             bottomRight:borderRadiusNum0
              bottomLeft:borderRadiusNum1];
        
    }
    else if (radiusNums.count == 3)
    {
        containerView.layer.cornerRadius = 0;
        CGFloat borderRadiusNum0 = [[radiusNums objectAtIndex:0] floatValue];
        CGFloat borderRadiusNum1 = [[radiusNums objectAtIndex:1] floatValue];
        CGFloat borderRadiusNum2 = [[radiusNums objectAtIndex:2] floatValue];
        
        [self radiusView:containerView
                 topLeft:borderRadiusNum0
                topRight:borderRadiusNum1
             bottomRight:borderRadiusNum2
              bottomLeft:borderRadiusNum1];
        
    }
    else if (radiusNums.count == 4)
    {
        containerView.layer.cornerRadius = 0;
        CGFloat borderRadiusNum0 = [[radiusNums objectAtIndex:0] floatValue];
        CGFloat borderRadiusNum1 = [[radiusNums objectAtIndex:1] floatValue];
        CGFloat borderRadiusNum2 = [[radiusNums objectAtIndex:2] floatValue];
        CGFloat borderRadiusNum3 = [[radiusNums objectAtIndex:2] floatValue];
        
        [self radiusView:containerView
                 topLeft:borderRadiusNum0
                topRight:borderRadiusNum1
             bottomRight:borderRadiusNum2
              bottomLeft:borderRadiusNum3];
    }
    else
    {
        NSAssert(NO, @"something error");
    }
}

- (void)radiusView:(UIView *)targetView
           topLeft:(CGFloat)topLeftRadius
          topRight:(CGFloat)topRightRadius
       bottomRight:(CGFloat)bottomRightRadius
        bottomLeft:(CGFloat)bottomLeftRadius
{
    CGFloat maxRadius = MIN(targetView.bounds.size.width/2, targetView.bounds.size.height/2);
    topLeftRadius = MIN(topLeftRadius, maxRadius);
    topRightRadius = MIN(topRightRadius, maxRadius);
    bottomRightRadius = MIN(bottomRightRadius, maxRadius);
    bottomLeftRadius = MIN(bottomLeftRadius, maxRadius);
    
    CGFloat minx = CGRectGetMinX(targetView.bounds);
    CGFloat miny = CGRectGetMinY(targetView.bounds);
    CGFloat maxx = CGRectGetMaxX(targetView.bounds);
    CGFloat maxy = CGRectGetMaxY(targetView.bounds);
    
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(minx + topLeftRadius, miny)];
    [path addLineToPoint:CGPointMake(maxx - topRightRadius, miny)];
    [path addArcWithCenter:CGPointMake(maxx - topRightRadius, miny + topRightRadius) radius: topRightRadius startAngle: 3 * M_PI_2 endAngle: 0 clockwise: YES];
    [path addLineToPoint:CGPointMake(maxx, maxy - bottomRightRadius)];
    [path addArcWithCenter:CGPointMake(maxx - bottomRightRadius, maxy - bottomRightRadius) radius: bottomRightRadius startAngle: 0 endAngle: M_PI_2 clockwise: YES];
    [path addLineToPoint:CGPointMake(minx + bottomLeftRadius, maxy)];
    [path addArcWithCenter:CGPointMake(minx + bottomLeftRadius, maxy - bottomLeftRadius) radius: bottomLeftRadius startAngle: M_PI_2 endAngle:M_PI clockwise: YES];
    [path addLineToPoint:CGPointMake(minx, miny + topLeftRadius)];
    [path addArcWithCenter:CGPointMake(minx + topLeftRadius, miny + topLeftRadius) radius: topLeftRadius startAngle: M_PI endAngle:3 * M_PI_2 clockwise: YES];
    [path closePath];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.path = path.CGPath;
    targetView.layer.mask = maskLayer;
}

- (NSArray <NSNumber *>*)getRadiusNumsByStrs:(NSArray <NSString *>*)raidusStrs
{
    NSMutableArray *radiusNums = [NSMutableArray array];
    for (NSString *raidusStr in raidusStrs)
    {
        CGFloat radius = [self getRadiusByStr:raidusStr];
        [radiusNums addObject:[NSNumber numberWithFloat:radius]];
    }
    return radiusNums;
}

- (CGFloat)getRadiusByStr:(NSString *)raduisStr
{
    if (![raduisStr isKindOfClass:[NSString class]])
    {
        return 0;
    }
    raduisStr = [raduisStr stringByReplacingOccurrencesOfString:@"px" withString:@""];
    CGFloat borderRadiusNum = [raduisStr floatValue];
    if (borderRadiusNum > 1000 || borderRadiusNum < 0) {
        return 0;
    }
    return borderRadiusNum;
}

@end
