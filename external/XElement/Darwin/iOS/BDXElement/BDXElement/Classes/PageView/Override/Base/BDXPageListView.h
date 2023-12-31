//
//  BDXPageListView.h
//  BDXElement
//
//  Created by AKing on 2021/2/6.
//

#import <UIKit/UIKit.h>
#import "BDXCategoryListContainerView.h"
#import "BDXPagerListContainerView.h"

@interface BDXPageListView : UIView <BDXCategoryListContentViewDelegate, BDXPagerViewListViewDelegate>

@property (nonatomic, weak) id<BDXPagerViewListViewDelegate> delegate;

@end
