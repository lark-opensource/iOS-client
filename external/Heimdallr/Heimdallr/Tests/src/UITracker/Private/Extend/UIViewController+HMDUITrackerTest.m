//
//  UIViewController+HMDUITrackerTest.m
//  Heimdallr
//
//  Created by sunrunwang on sometime
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDProtector.h"
#import "HMDDynamicCall.h"
#import "HMDSwizzle.h"
#import "UIViewController+HMDUITracker.h"

static BOOL questionMark;

@interface CAViewController1 : UIViewController

- (void)viewWillAppear:(BOOL)animated;

- (void)viewDidAppear:(BOOL)animated;

@property(nonatomic) NSString *myName;

@end

@interface UIViewControllerHMDUITrackerTest : XCTestCase

@end

@implementation UIViewControllerHMDUITrackerTest

+ (void)setUp {
    [UIViewController hmd_startSwizzle];
}

- (void)test_viewWillAndDidAppear {
    CAViewController1 *vc = [[CAViewController1 alloc] initWithNibName:nil bundle:nil];
    XCTAssert(object_getClass(vc) != CAViewController1.class);
    
    questionMark = NO;
    [vc viewWillAppear:YES];
    XCTAssert(questionMark);
    
    questionMark = NO;
    [vc viewDidAppear:YES];
    XCTAssert(questionMark);
}

static NSMutableSet<NSString *> *obvervedPathSet;

- (void)test_simpleKVO {
    [obvervedPathSet removeAllObjects];
    CAViewController1 *vc = [[CAViewController1 alloc] initWithNibName:@"CAViewController1" bundle:nil];
    [vc addObserver:self forKeyPath:@"myName" options:0 context:nil];
    
    vc.myName = @"goodBoy";
    vc.myName = nil;
    XCTAssert([obvervedPathSet containsObject:@"myName"]);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if(obvervedPathSet == nil) obvervedPathSet = [NSMutableSet set];
    [obvervedPathSet addObject:keyPath];
}

@end

@implementation CAViewController1

- (void)viewWillAppear:(BOOL)animated {
    XCTAssert(strcmp(sel_getName(_cmd), "viewWillAppear:") == 0);
    XCTAssert(object_getClass(self) != CAViewController1.class);
    questionMark = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    XCTAssert(strcmp(sel_getName(_cmd), "viewDidAppear:") == 0);
    XCTAssert(object_getClass(self) != CAViewController1.class);
    questionMark = YES;
}

@end

