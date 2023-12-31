//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Lynx/LynxUIScroller.h>
#import <Lynx/LynxUIView.h>
#import <Lynx/LynxPropsProcessor.h>
#import "BDXLynxRefreshView.h"
#import "BDXLynxRefreshHeader.h"
#import "BDXLynxRefreshFooter.h"
#import <MJRefresh/MJRefreshHeader.h>
#import <MJRefresh/MJRefreshAutoFooter.h>

@interface BDXLynxRefreshView (Test)
- (void)startLoadMore;
@end

@interface BDXLynxViewRefreshViewUnitTest : XCTestCase
@property (nonatomic, strong) BDXLynxRefreshView *refreshview;
@property (nonatomic, strong) UIWindow *window;
@end

@implementation BDXLynxViewRefreshViewUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
    self.refreshview = [[BDXLynxRefreshView alloc] init];
    [self.refreshview updateFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)
                        withPadding:UIEdgeInsetsZero
                             border:UIEdgeInsetsZero
                withLayoutAnimation:NO];
    
    BDXLynxRefreshHeader *header = [[BDXLynxRefreshHeader alloc] init];
    [header updateFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 40.0f)
                        withPadding:UIEdgeInsetsZero
                             border:UIEdgeInsetsZero
                withLayoutAnimation:NO];
    
    BDXLynxRefreshFooter *footer = [[BDXLynxRefreshFooter alloc] init];
    [footer updateFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 40.0f)
                        withPadding:UIEdgeInsetsZero
                             border:UIEdgeInsetsZero
                withLayoutAnimation:NO];
    
    LynxUIScroller *scroller = [[LynxUIScroller alloc] init];
    [scroller updateFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)
                        withPadding:UIEdgeInsetsZero
                             border:UIEdgeInsetsZero
                withLayoutAnimation:NO];
    
    [LynxPropsProcessor updateProp:@1 withKey:@"scroll-y" forUI:scroller];
    CGSize size = (CGSize){UIScreen.mainScreen.bounds.size.width, 100.0f};
    for (int i = 0; i < 10; i++) {
      LynxUI *child = [[LynxUIView alloc] init];
        [child updateFrame:(CGRect){{0.0f, size.height * i}, size}
                  withPadding:UIEdgeInsetsZero
                       border:UIEdgeInsetsZero
          withLayoutAnimation:false];
      [scroller insertChild:child atIndex:i];
    }
    
    [self.refreshview insertChild:header atIndex:0];
    [self.refreshview insertChild:scroller atIndex:1];
    [self.refreshview insertChild:footer atIndex:2];
    
    [LynxPropsProcessor updateProp:@1 withKey:@"enable-refresh" forUI:self.refreshview];
    [LynxPropsProcessor updateProp:@1 withKey:@"enable-loadmore" forUI:self.refreshview];
    [self.refreshview layoutDidFinished];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window.rootViewController.view addSubview:self.refreshview.view];
    [self.window makeKeyAndVisible];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testEnableDisableScrollLoadmoreWithAutoLoadMore {
    XCTAssertNotNil(self.refreshview.view);
    BDXLynxRefreshView *mockRefreshView = OCMPartialMock(self.refreshview);
    
    XCTestExpectation* exception = [self expectationWithDescription:@"didn't trigger loadmore with enable-auto-loadmore"];
    mockRefreshView.scrollView.scrollEnabled = NO;
    [LynxPropsProcessor updateProp:@1 withKey:@"ios-enable-loadmore-when-scroll-disabled" forUI:mockRefreshView];
    
    [LynxPropsProcessor updateProp:@1 withKey:@"enable-auto-loadmore" forUI:mockRefreshView];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [mockRefreshView.scrollView setContentOffset:(CGPoint){0.0f, 100.0f}];
        [mockRefreshView.scrollView setContentOffset:(CGPoint){0.0f, 1100.0f}];
        sleep(2);
        OCMVerify(times(1), [mockRefreshView startLoadMore]);
        [exception fulfill];
    });
    
    [self waitForExpectationsWithTimeout:4 handler:^(NSError *_Nullable error) {}];
}

- (void)testEnableDisableScrollLoadmoreWithoutAutoLoadMore {
    XCTAssertNotNil(self.refreshview.view);
    BDXLynxRefreshView *mockRefreshView = OCMPartialMock(self.refreshview);
    
    XCTestExpectation* exception = [self expectationWithDescription:@"didn't trigger loadmore without enable-auto-loadmore"];
    mockRefreshView.scrollView.scrollEnabled = NO;
    [LynxPropsProcessor updateProp:@1 withKey:@"ios-enable-loadmore-when-scroll-disabled" forUI:mockRefreshView];
    
    [LynxPropsProcessor updateProp:@0 withKey:@"enable-auto-loadmore" forUI:mockRefreshView];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [mockRefreshView.scrollView setContentOffset:(CGPoint){0.0f, 100.0f}];
        [mockRefreshView.scrollView setContentOffset:(CGPoint){0.0f, 1100.0f}];
        sleep(2);
        OCMVerify(times(1), [mockRefreshView startLoadMore]);
        [exception fulfill];
    });
    
    [self waitForExpectationsWithTimeout:4 handler:^(NSError *_Nullable error) {}];
}

@end
