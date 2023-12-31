//
//  BDXPageBaseView.h
//  BDXElement
//
//  Created by AKing on 2021/2/6.
//

#import <UIKit/UIKit.h>
#import "BDXCategoryView.h"
#import "BDXCategoryListContainerView.h"

#define WindowsSize [UIScreen mainScreen].bounds.size

@protocol BDXPageBaseViewDelegate <BDXCategoryListContainerViewDelegate, BDXCategoryViewDelegate>
@optional
- (BOOL)viewpagerIsDynamic;
@end

@interface BDXPageBaseView : UIView <BDXCategoryListContainerViewDelegate>

@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) BDXCategoryBaseView *categoryView;
@property (nonatomic, strong) id<BDXCategoryViewListContainer> listContainerView;
@property (nonatomic, assign) CGFloat categoryViewHeight;//tab hegiht,default 50

@property (nonatomic, weak) id<BDXPageBaseViewDelegate> delegate;

- (void)loadView;

- (BDXCategoryBaseView *)preferredCategoryView;
- (CGFloat)preferredCategoryViewHeight;

@end
