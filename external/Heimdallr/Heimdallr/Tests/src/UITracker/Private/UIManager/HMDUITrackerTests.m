//
//  HMDUITrackerTests.m
//  HMDUITrackerTests
//
//  Created by sunrunwang on whatever
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDProtector.h"
#import "HMDDynamicCall.h"
#import "HMDSwizzle.h"
#import "UIViewController+HMDUITracker.h"
#import "HMDUITrackableContext.h"
#import "HMDUITracker.h"
#import "HMDMacro.h"
#import "pthread_extended.h"

@interface CAViewController2 : UIViewController

@end

@interface HMDUITrackerTests : XCTestCase

@end

@implementation HMDUITrackerTests

CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNUSED_VALUE

static NSMutableSet<NSString *> *globalSet;

+ (void)setUp { // actually only called once ?
    static BOOL setupComplete = NO;
    
    NSCondition *condition = [[NSCondition alloc] init];
    if (@available(iOS 10.0, *)) {
        [NSThread detachNewThreadWithBlock:^{
            [HMDUITracker.sharedInstance start];
            [condition lock];
            setupComplete = YES;
            [condition signal];
            [condition unlock];
        }];
    } else {    // 这会测试失败是吧
        setupComplete = YES;
    }
    
    [condition lock];
    while(!setupComplete) [condition wait];
    [condition unlock];
    
    
    HMD_mockClassTreeForInstanceMethod(HMDUITracker,
                                       trackWithName:event:parameters:,
    ^(HMDUITracker *thisSelf, NSString *name, NSString *event, NSDictionary *parameters) {
        fprintf(stdout, "[XCTest] -[HMDUITracker trackWithName:\"%s\" event:\"%s\" parameters:]\n",
                name.UTF8String, event.UTF8String);
        DC_OB(thisSelf, MOCK_trackWithName:event:parameters:, name, event, parameters);
    });
    
    HMD_mockClassTreeForInstanceMethod(HMDUITracker,
                                       trackableContext:eventWithName:parameters:,
    ^(HMDUITracker *thisSelf, HMDUITrackableContext *context, NSString *event, NSDictionary *parameters){
        fprintf(stdout, "[XCTest] -[HMDUITracker trackableContext:\"%s\" eventWithName:\"%s\" parameters:]\n",
                context.trackName.UTF8String, event.UTF8String);
        
        if(globalSet == nil) globalSet = [NSMutableSet set];
        [globalSet addObject:event];
        
        DC_OB(thisSelf, MOCK_trackableContext:eventWithName:parameters:, context, event, parameters);
    });
}

- (void)test_trackWithNameEventParameters {
    CAViewController2 *vc = [[CAViewController2 alloc] initWithNibName:nil bundle:nil];
    
    [globalSet removeAllObjects];
    
    [vc view];
    [vc viewWillAppear:YES];
    [vc viewDidAppear:YES];
    [vc viewWillDisappear:YES];
    [vc viewDidDisappear:YES];
    
    XCTAssert([globalSet containsObject:@"load"]);
    XCTAssert([globalSet containsObject:@"appear"]);
    XCTAssert([globalSet containsObject:@"disappear"]);
}

CLANG_DIAGNOSTIC_POP

@end

@implementation CAViewController2

- (void)loadView {
    XCTAssert(strcmp(sel_getName(_cmd), "loadView") == 0);
    XCTAssert(object_getClass(self) != CAViewController2.class);
    [super loadView];
}

- (void)viewDidLoad {
    XCTAssert(strcmp(sel_getName(_cmd), "viewDidLoad") == 0);
    XCTAssert(object_getClass(self) != CAViewController2.class);
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    XCTAssert(strcmp(sel_getName(_cmd), "viewWillAppear:") == 0);
    XCTAssert(object_getClass(self) != CAViewController2.class);
}

- (void)viewDidAppear:(BOOL)animated {
    XCTAssert(strcmp(sel_getName(_cmd), "viewDidAppear:") == 0);
    XCTAssert(object_getClass(self) != CAViewController2.class);
}

- (void)viewWillDisappear:(BOOL)animated {
    XCTAssert(strcmp(sel_getName(_cmd), "viewWillDisappear:") == 0);
    XCTAssert(object_getClass(self) != CAViewController2.class);
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    XCTAssert(strcmp(sel_getName(_cmd), "viewDidDisappear:") == 0);
    XCTAssert(object_getClass(self) != CAViewController2.class);
    [super viewDidDisappear:animated];
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    XCTAssert(strcmp(sel_getName(_cmd), "presentViewController:animated:completion:") == 0);
    XCTAssert(object_getClass(self) != CAViewController2.class);
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    XCTAssert(strcmp(sel_getName(_cmd), "dismissViewControllerAnimated:completion:") == 0);
    XCTAssert(object_getClass(self) != CAViewController2.class);
}

@end
