//
//  UICollectionViewCell+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/24.
//

#import "UICollectionViewCell+AutoTrack.h"
#import "UIResponder+AutoTrack.h"
#import "UIView+AutoTrack.h"
#import <objc/runtime.h>
#import "BDAutoTrackSwizzle.h"

@implementation UICollectionViewCell (AutoTrack)

- (NSString *)bd_responderPath {
    UIResponder *parent = self.nextResponder;
    return [NSString stringWithFormat:@"%@%@%@[]",[parent bd_responderPath], kBDViewPathSeperator,  NSStringFromClass(self.class)];
}

- (NSMutableArray<NSIndexPath *> *)bd_indexPath {
    UIResponder *parent = self.nextResponder;
    NSIndexPath *index = nil;
    if ([parent isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)parent;
        index = [collectionView indexPathForCell:self];
    }

    NSMutableArray<NSIndexPath *> * indexs= [super bd_indexPath];
    if (index)  [indexs addObject:index];

    return indexs;
}

- (CGPoint)bd_cellTouchPoint {
    return [objc_getAssociatedObject(self, @selector(bd_cellTouchPoint)) CGPointValue];
}

- (void)setBd_cellTouchPoint:(CGPoint)point {
    NSValue *value = [NSValue valueWithCGPoint:point];
    objc_setAssociatedObject(self, @selector(bd_cellTouchPoint), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)load {
    static IMP original_Event_Imp = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        original_Event_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(touchesEnded:withEvent:), ^(UICollectionViewCell *_self, NSSet<UITouch *> *touches, UIEvent *event){
            CGPoint point = [[touches anyObject] locationInView:_self];
            [_self setBd_cellTouchPoint:point];
            if (original_Event_Imp) {
                ((void ( *)(id, SEL, NSSet<UITouch *> *,UIEvent *))original_Event_Imp)(_self, @selector(touchesEnded:withEvent:), touches, event);
            }
        });
    });
}

@end
