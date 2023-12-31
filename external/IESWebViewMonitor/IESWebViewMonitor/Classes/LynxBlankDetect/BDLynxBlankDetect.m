//
//  BDLynxBlankDetect.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/5/21.
//

#import "BDLynxBlankDetect.h"
#import <Lynx/LynxTextView.h>
#import <Lynx/LynxUIText.h>
#import <objc/runtime.h>
#import "LynxView+Monitor.h"
#import "IESLiveMonitorUtils.h"
#import "BDMonitorThreadManager.h"

#define STRING_NOT_EMPTY(str) (str?str:@"")
#define BTD_isEmptyString(param)        ( !(param) ? YES : ([(param) isKindOfClass:[NSString class]] ? (param).length == 0 : NO) )

static void MethodSwizzle(Class class, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

#pragma mark --- View + BDLynxBlankDetect

@implementation UIView (BDLynxBlankDetect)

- (float)checkWithAllowListBlock:(BOOL(^)(UIView*))allowListBlock lynxView:(LynxView *)lynxView {
    CGFloat viewWidth = lynxView.frame.size.width;
    CGFloat viewHeight = lynxView.frame.size.height;
    if (viewWidth == 0 || viewHeight == 0) { return 1.0f; }

    long long beginTs = [IESLiveMonitorUtils formatedTimeInterval];
    float contentRate = [BDLynxBlankDetect startCheckWithView:self allowListBlcok:allowListBlock];
    long long costTime = [IESLiveMonitorUtils formatedTimeInterval] - beginTs;
    
    NSDictionary *dic = @{
        @"event_type":@"blank",
        @"effective_percentage":@(contentRate),
        @"cost_time":@(costTime)
    };
    [lynxView.performanceDic reportDirectlyWithDic:dic evType:@"blank"];
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMainThread:^{
        [self bdhm_tiggerLynxBlankCallback:lynxView effectiveRate:contentRate costTime:costTime];
    }];

    return contentRate;
}

- (void)switchOnAutoCheckBlank:(BOOL)isOn lynxView:(LynxView *)lynxView {
    [self setBdwm_containedLynxView:lynxView];
    [self setBdwm_isTurnOnLynxBlankDetect:isOn];
}

- (BOOL)bdwm_isTurnOnLynxBlankDetect {
    return objc_getAssociatedObject(self, @"bdwm_isTurnOnLynxBlankDetect");
}

- (void)setBdwm_isTurnOnLynxBlankDetect:(BOOL)bdwm_isTurnOnLynxBlankDetect {
    objc_setAssociatedObject(self
                             , @"bdwm_isTurnOnLynxBlankDetect"
                             , @(bdwm_isTurnOnLynxBlankDetect)
                             , OBJC_ASSOCIATION_RETAIN);
    if (bdwm_isTurnOnLynxBlankDetect) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            MethodSwizzle(self.class
                          ,@selector(removeFromSuperview)
                          ,@selector(bdwm_blank_removeFromSuperview));
        });
    }
}

- (void)bdwm_blank_removeFromSuperview {
    if ([self bdwm_isTurnOnLynxBlankDetect]) {
        [self checkWithAllowListBlock:nil lynxView:[self bdwm_containedLynxView]];
    }
    [self bdwm_blank_removeFromSuperview];
}

- (void)setBdwm_containedLynxView:(LynxView *)bdwm_containedLynxView {
    id __weak weakObject = bdwm_containedLynxView;
    id (^block)(void) = ^{ return weakObject; };
    objc_setAssociatedObject(self,
                             @"bdwm_containedLynxView",
                             block,
                             OBJC_ASSOCIATION_COPY);
}

- (LynxView *)bdwm_containedLynxView {
    id (^block)(void) = objc_getAssociatedObject(self,
                                                 @"bdwm_containedLynxView");
    return (block ? block() : nil);
}

#pragma mark --- blank view call back
- (void)bdhm_addLynxBlankListener:(id<BDHMLynxBlankListenerDelegate>)listener {
    if (!listener) { return; }
    if (!self.bdhm_blankListeners) {
        self.bdhm_blankListeners = [NSHashTable weakObjectsHashTable];
    }
    [self.bdhm_blankListeners addObject:listener];
}

- (void)bdhm_removeLynxBlankListner:(id<BDHMLynxBlankListenerDelegate>)listener {
    if (!listener) { return; }
    if (!self.bdhm_blankListeners) { return; }
    [self.bdhm_blankListeners removeObject:listener];
}

- (NSHashTable *)bdhm_blankListeners {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBdhm_blankListeners:(NSHashTable *)bdhm_blankListeners {
    objc_setAssociatedObject(self, @selector(bdhm_blankListeners), bdhm_blankListeners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)bdhm_tiggerLynxBlankCallback:(LynxView *)lynView effectiveRate:(float)effectiveRate costTime:(long)costTime {
    if (self.bdhm_blankListeners) {
        for (id <BDHMLynxBlankListenerDelegate> listenter in self.bdhm_blankListeners) {
            if ([listenter respondsToSelector:@selector(bdhmLynxBlankResult:effectivePercentage:costTime:)]) {
                [listenter bdhmLynxBlankResult:lynView effectivePercentage:effectiveRate costTime:costTime];
            }
        }
    }
}

@end

@implementation BDLynxBlankDetect

+ (float)startCheckWithView:(UIView *)detectView allowListBlcok:(BOOL(^)(UIView*))allowListBlock {
    CGFloat oriWidth = detectView.bounds.size.width;
    CGFloat oriHeight = detectView.bounds.size.height;

    // 最长边小于100 的话 等比例缩小后 短边一定也小于100
    CGFloat maxSide = oriHeight > oriWidth ? oriHeight : oriWidth;
    NSInteger maxLength = maxSide > 100 ? 100 : ((NSInteger)maxSide);
    float maxScale = 1;
    if (maxSide > 0) {
        maxScale = maxLength / maxSide;
    }

    // 等比例缩小
    size_t width = (NSInteger)(oriWidth * maxScale);
    size_t height = (NSInteger)(oriHeight * maxScale);

    float percentage = 0.f;
    if (width > 0 && height > 0) {
        size_t length = width * height;
        uint8_t * flag = (uint8_t*)calloc(1, length);
        for (NSInteger i = 0; i < length; i++)
            flag[i] = 0;
        
        [self p_calcValidAreaPercentageWithOriginalView:detectView
                                            currentView:detectView
                                                   flag:flag
                                              widthUnit:oriWidth / width
                                             heightUnit:oriHeight / height
                                      maxWidthUnitCount:width
                                     maxHeightUnitCount:height
                                         allowListBlcok:allowListBlock];
        
        size_t result = 0;
        for (size_t index = 0; index < length; index ++) {
            if (flag[index] > 0) {
                result++;
            }
        }
        percentage = (float)result / (float)length;
        if (flag)
            free(flag);
    }
    return percentage;
}

+ (void)p_calcValidAreaPercentageWithOriginalView:(UIView *)originalView
                                      currentView:(UIView *)currentView
                                             flag:(uint8_t [])flag
                                        widthUnit:(CGFloat)widthUnit
                                       heightUnit:(CGFloat)heightUnit
                                maxWidthUnitCount:(size_t)maxWidthUnitCount
                               maxHeightUnitCount:(size_t)maxHeightUnitCount
                                   allowListBlcok:(BOOL(^)(UIView*))allowListBlock {
    
    if (!currentView || ![currentView isKindOfClass:[UIView class]] ||
        !originalView || ![originalView isKindOfClass:[UIView class]]) {
        return;
    }
    
    if ([self checkIfSingleViewIsValid:currentView allowListBlcok:allowListBlock]) {
        // 计算映射frame
        CGRect currentViewRect;
        if (originalView != currentView) {
            currentViewRect = [currentView.superview convertRect:currentView.frame toView:originalView];
        } else {
            currentViewRect = currentView.frame;
        }
        
        size_t x = MIN(MAX(round(currentViewRect.origin.x / widthUnit), 0), maxWidthUnitCount);
        size_t y = MIN(MAX(round(currentViewRect.origin.y / heightUnit), 0), maxHeightUnitCount);
        size_t widthLength = round(currentViewRect.size.width / widthUnit);
        size_t heightLength = round(currentViewRect.size.height / heightUnit);
        
        widthLength = (widthLength + x) > maxWidthUnitCount ? 0 : widthLength;
        heightLength = (heightLength + y) > maxHeightUnitCount ? 0 : heightLength;

        for (size_t index = y; index < y + heightLength; index++) {
            if ((index * maxWidthUnitCount + x + widthLength) < maxWidthUnitCount *maxHeightUnitCount) {
                memset(flag + index * maxWidthUnitCount + x, 1, widthLength);
            }
        }
    }
    
    NSArray *subviews = [currentView subviews];
    for (int i = 0; i < [subviews count]; i++) {
        UIView *subView = [subviews objectAtIndex:i];
        
        [self p_calcValidAreaPercentageWithOriginalView:originalView
                                            currentView:subView
                                                   flag:flag
                                              widthUnit:widthUnit
                                             heightUnit:heightUnit
                                      maxWidthUnitCount:maxWidthUnitCount
                                     maxHeightUnitCount:maxHeightUnitCount
                                         allowListBlcok:(BOOL(^)(UIView*))allowListBlock];
    }
}

+ (BOOL)checkIfSingleViewIsValid:(UIView *)view allowListBlcok:(BOOL(^)(UIView*))allowListBlock {
    if (!view || ![view isKindOfClass:[UIView class]] || view.alpha == 0.f || view.hidden || view.frame.size.width == 0.f || view.frame.size.height == 0.f) {
        return NO;
    }
    if (allowListBlock && allowListBlock(view)) {
        return YES;
    }
    
    if ([view isKindOfClass:[UILabel class]] &&
        (!BTD_isEmptyString(((UILabel *)view).text) || !((UILabel *)view).attributedText.length)) {
        return YES;
    }
    
    if ([view isKindOfClass:[LynxTextView class]] && !BTD_isEmptyString(((LynxTextView *)view).ui.renderer.attrStr)) {
        return YES;
    }

    if ([view isKindOfClass:[UIImageView class]] && ((UIImageView *)view).image) {
        return YES;
    }

    if ([view isKindOfClass:[UITextView class]] &&
        (!BTD_isEmptyString(((UITextView *)view).text) || !((UITextView *)view).attributedText.length)) {
        return YES;
    }

    Class xLabelCls = NSClassFromString(@"YYLabel");
    if (xLabelCls && [view isKindOfClass:xLabelCls]) {
        if ([view respondsToSelector:@selector(attributedText)]) {
            id attributedText = [view performSelector:@selector(attributedText)];
            if (attributedText &&
                [attributedText isKindOfClass:[NSAttributedString class]] &&
                ((NSAttributedString *)attributedText).length > 0) {
                return YES;
            }
        } else if ([view respondsToSelector:@selector(text)]) {
            id text = [view performSelector:@selector(text)];
            if (text &&
                [text isKindOfClass:[NSString class]] &&
                ((NSString *)text).length > 0) {
                return YES;
            }
        }
    }
    
    Class bgLayer = NSClassFromString(@"LynxBackgroundSubLayer");
    if (view.layer && bgLayer) {
        NSArray *sublayers = view.layer.sublayers;
        for (CALayer *layerItem in sublayers) {
            if ([layerItem isKindOfClass:bgLayer]) {
                return YES;
            }
        }
    }
    
    return NO;
}

@end



