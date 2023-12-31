//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <XCTest/XCTest.h>
#import "BDXLynxSwiperPageView.h"
#import <Lynx/LynxUI.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import "BDXLynxSwpierCell.h"

@interface BDXLynxSwiperPageView (Testing)
- (void)timerFired:(NSTimer *)timer;
@property (nonatomic, assign) NSInteger numberOfItems;
- (void)scrollToNearlyIndexAtDirection:(BDXLynxSwiperScrollDirection)direction animate:(BOOL)animate;
- (BDXLynxSwiperIndexSection)calculateIndexSectionWithOffset:(CGFloat)offset;
- (void)scrollToItemAtIndexSection:(BDXLynxSwiperIndexSection)indexSection animate:(BOOL)animate;
@end

@implementation BDXLynxSwiperPageView (Testing)

@end

@interface BDXLynxSwiperPageViewUnitTest : XCTestCase
@end

@implementation BDXLynxSwiperPageViewUnitTest

- (void)setUp {
  
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}


- (void)testScrollRTL {
    BDXLynxSwiperPageView *pageView = [[BDXLynxSwiperPageView alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    pageView.dataSource = self;
    pageView.numberOfItems = 10;
    [pageView.collectionView setContentSize:CGSizeMake(300 * 10, 50)];
    ((UICollectionViewFlowLayout *)pageView.collectionView.collectionViewLayout).itemSize = CGSizeMake(300, 50);
    ((UICollectionViewFlowLayout *)pageView.collectionView.collectionViewLayout).minimumLineSpacing = 0;
    ((UICollectionViewFlowLayout *)pageView.collectionView.collectionViewLayout).minimumInteritemSpacing = 0;
    XCTAssert(pageView.collectionView.contentOffset.x == 0);
    [pageView scrollToItemAtIndexSection:[pageView calculateIndexSectionWithOffset:0] animate:NO];
    [pageView scrollToNearlyIndexAtDirection:BDXLynxSwiperScrollDirectionRight animate:NO];
    XCTAssert(pageView.collectionView.contentOffset.x == 300);
}


- (NSInteger)numberOfItemsInPagerView:(BDXLynxSwiperPageView *)pageView {
    return 10;
}

- (UICollectionViewCell *)pagerView:(BDXLynxSwiperPageView *)pagerView cellForItemAtIndex:(NSInteger)index
{
    BDXLynxSwpierCell *cell = [pagerView dequeueReusableCellWithReuseIdentifier:@"BDXLynxSwiperCell" forIndex:index];
    [cell.contentView addSubview: [[UIView alloc] initWithFrame:pagerView.bounds]];
    return cell;
}

- (UIView *)pagerView:(BDXLynxSwiperPageView *)pagerView viewForItemAtIndex:(NSInteger)index {
  return [[UIView alloc] initWithFrame:pagerView.bounds];
}

- (BDXLynxSwiperViewLayout *)layoutForPagerView:(BDXLynxSwiperPageView *)pageView {
    BDXLynxSwiperViewLayout *layout = [[BDXLynxSwiperViewLayout alloc] init];
    layout.itemSize = CGSizeMake(300, 50);
    layout.isRTL = YES;
    return layout;
}


@end
