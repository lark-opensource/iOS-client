//
//  BDXPageGestureCollectionView.m
//  BDXElement
//
//  Created by AKing on 2020/9/21.
//

#import "BDXPageGestureCollectionView.h"

@implementation BDXPageGestureCollectionView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"UILayoutContainerView")]) {
        if ((otherGestureRecognizer.state == UIGestureRecognizerStateBegan || otherGestureRecognizer.state == UIGestureRecognizerStatePossible)&& (self.needReserveEdgeBack ? YES : self.contentOffset.x <= 0)) {
            return YES;
        }
    }
    return NO;
}

@end
