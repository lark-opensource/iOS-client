//
//  AWETabView.h
//  Aweme
//
//  Created by hanxu on 2017/4/10.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^AWETabViewClickedTabBlock)(NSInteger tabNum);
typedef BOOL (^AWETabViewShouldClickedTabBlock)(NSInteger tabNum);

@interface AWETabView : UIView

@property (nonatomic, copy) AWETabViewClickedTabBlock clickedTabBlock;
@property (nonatomic, copy) AWETabViewShouldClickedTabBlock shouldClickTabBlock;
- (void)setNamesOfTabs:(NSArray *)namesOfTabs views:(NSArray *)views withStartIndex:(NSInteger)startIndex;
- (void)setNamesOfTabs:(NSArray *)namesOfTabs views:(NSArray *)views;

@end
