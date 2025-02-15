/*
 OLEContainerScrollView
 
 Copyright (c) 2014 Ole Begemann.
 https://github.com/ole/OLEContainerScrollView
 */

#import <UIKit/UIKit.h>

#import "LynxOLEContainerScrollView+Swizzling.h"
#import "LynxOLESwizzling.h"
#import "LynxOLEContainerScrollView.h"
#import "LynxOLEContainerScrollViewScrollingOffset.h"

void swizzleUICollectionViewLayoutFinalizeCollectionViewUpdates()
{
    Class classToSwizzle = [UICollectionViewLayout class];
    SEL selectorToSwizzle = @selector(finalizeCollectionViewUpdates);
    
    __block IMP originalIMP = NULL;
    originalIMP = LynxOLEReplaceMethodWithBlock(classToSwizzle, selectorToSwizzle, ^(UICollectionViewLayout *_self) {
        // Call original implementation
        ((void ( *)(id, SEL))originalIMP)(_self, selectorToSwizzle);
        
        // Manually set the collection view's contentSize to its new size (after the updates have been performed) to cause
        // a relayout of all views in the container scroll view.
        // We do this to animate the resizing of the collection view and its adjacent views in the container scroll view
        // in sync with the cell update animations (finalizeCollectionViewUpdates is called inside the animation block).
        // If we don't do this, the collection view will set its new content size only after the cell update animations
        // have finished, which is too late for us.
        UICollectionView *collectionView = _self.collectionView;
        BOOL collectionViewIsInsideOLEContainerScrollView = [collectionView.superview isKindOfClass:[LynxOLEContainerScrollViewScrollingOffset class]];
        if (collectionViewIsInsideOLEContainerScrollView) {
            collectionView.contentSize = _self.collectionViewContentSize;
        }
    });
}

void swizzleUITableView()
{
    Class classToSwizzle = [UITableView class];
    NSString *obfuscatedSelector = [NSString stringWithFormat:@"_%@llAnimat%@hContext:", @"endCe", @"ionsWit"];
    SEL selectorToSwizzle = NSSelectorFromString(obfuscatedSelector);
    
    __block IMP originalIMP = NULL;
    originalIMP = LynxOLEReplaceMethodWithBlock(classToSwizzle, selectorToSwizzle, ^(UITableView *_self, id context) {
        // Call original implementation
        ((void ( *)(id, SEL, id))originalIMP)(_self, selectorToSwizzle, context);

        [UIView animateWithDuration:0.25 animations:^{

            // Manually set the table view's contentSize to its new size (after the updates have been performed) to cause
            // a relayout of all views in the container scroll view.
            // We do this to animate the resizing of the table view and its adjacent views in the container scroll view
            // in sync with the cell update animations. If we don't do this, the table view will set its new content size
            // only after the cell update animations have finished, which is too late for us.
            BOOL tableViewIsInsideOLEContainerScrollView = [_self.superview isKindOfClass:[LynxOLEContainerScrollViewScrollingOffset class]];
            if (tableViewIsInsideOLEContainerScrollView) {
                NSString *obfuscatedPropertyKey = [NSString stringWithFormat:@"_%@entSize", @"cont"];
                _self.contentSize = [[_self valueForKey:obfuscatedPropertyKey] CGSizeValue];
            }
        }];
    });
}
