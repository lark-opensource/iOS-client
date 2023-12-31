//
//  AWECenteredScrollFlowLayout.h
//  AWEStudio
//
//  Created by jindulys on 2018/12/11.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AWECenteredScrollFlowLayoutDelegate <NSObject>

- (void)collectionViewScrollStopAtIndex:(NSInteger)index;
- (NSInteger)collectionViewCurrentSelectedIndex;

@end

@interface AWECenteredScrollFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, weak) id<AWECenteredScrollFlowLayoutDelegate> delegate;
@property (nonatomic, assign) BOOL enableScale;
@property (nonatomic, copy) CGFloat (^ratioBlock)(CGFloat delta);

@end
