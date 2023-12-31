#import <XCTest/XCTest.h>
#import "LynxPropsProcessor.h"
#import "LynxTextRenderer.h"
#import "LynxUI.h"
#import "LynxUIImage.h"
#import "LynxUIMethodProcessor.h"
#import "LynxUIOwner+Accessibility.h"
#import "LynxUIOwner.h"
#import "LynxUIText.h"
#import "LynxView.h"

@interface LynxUI (TestAccessibility)
- (UIView *)accessibilityFocusedView;
- (NSArray *)accessibilityElementsWithA11yID;
- (void)requestAccessibilityFocus:(NSDictionary *)params
                       withResult:(LynxUIMethodCallbackBlock)callback;
- (void)fetchAccessibilityTargets:(NSDictionary *)params
                       withResult:(LynxUIMethodCallbackBlock)callback;
- (void)innerText:(NSDictionary *)params withResult:(LynxUIMethodCallbackBlock)callback;
@end

@interface LynxMockRootUI : NSObject
@property(nonatomic) UIView *view;
@end

@implementation LynxMockRootUI

@end

@interface LynxMockRootView : NSObject
@property(nonatomic) NSMutableDictionary<NSNumber *, LynxUI *> *uiHolder;
@property(nonatomic) NSMutableDictionary<NSString *, NSMutableArray<UIView *> *> *a11yIdHolder;
- (LynxUI *)findUIByIndex:(int)index;
- (nullable NSArray<UIView *> *)viewsWithA11yID:(NSString *)a11yID;
@property(nonatomic) LynxMockRootUI *rootUI;
@end

@implementation LynxMockRootView

- (instancetype)init {
  if (self = [super init]) {
    _uiHolder = [NSMutableDictionary dictionary];
    _a11yIdHolder = [NSMutableDictionary dictionary];
    _rootUI = [[LynxMockRootUI alloc] init];
  }
  return self;
}

- (void)addLynxUI:(LynxUI *)ui forIndex:(NSInteger)index {
  _uiHolder[@(index)] = ui;
}

- (void)addView:(UIView *)view forA11y:(NSString *)a11y {
  NSMutableArray<UIView *> *array = _a11yIdHolder[a11y];
  if (!array) {
    array = [NSMutableArray array];
    _a11yIdHolder[a11y] = array;
  }
  [array addObject:view];
}

- (LynxUI *)findUIByIndex:(int)index {
  return _uiHolder[@(index)];
}
- (nullable NSArray<UIView *> *)viewsWithA11yID:(NSString *)a11yID {
  return _a11yIdHolder[a11yID];
}
@end

@interface LynxMockContext : NSObject
@property(nonatomic) LynxMockRootView *rootView;
@property(nonatomic) LynxMockRootUI *rootUI;

@property(nonatomic, readonly) NSString *targetSdkVersion;
@property(nonatomic, readonly) BOOL defaultAutoResumeAnimation;
@property(nonatomic, readonly) BOOL defaultEnableNewTransformOrigin;
@end

@implementation LynxMockContext

- (instancetype)init {
  if (self = [super init]) {
    _rootView = [[LynxMockRootView alloc] init];
    _targetSdkVersion = @"2.3";
    _rootUI = [[LynxMockRootUI alloc] init];
  }
  return self;
}
@end

@interface LynxContextHolder : NSObject
@property(nonatomic, strong) LynxMockContext *context;
@property(nonatomic, strong) LynxUI *ui;
@end

@implementation LynxContextHolder
@end

@interface LynxUI_AccessibilityUnitTest : XCTestCase

@end

@implementation LynxUI_AccessibilityUnitTest

- (void)setUp {
}

- (LynxContextHolder *)setUpHolder {
  LynxContextHolder *holder = [[LynxContextHolder alloc] init];
  holder.context = [[LynxMockContext alloc] init];
  holder.ui = [[LynxUI alloc] initWithView:[[UIView alloc] init]];
  holder.ui.sign = 1;
  holder.context = [[LynxMockContext alloc] init];
  holder.ui.context = (LynxUIContext *)holder.context;
  holder.context.rootView.rootUI.view = holder.ui.view;
  holder.context.rootUI.view = holder.ui.view;
  return holder;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testRequestAccessibilityFocus {
  LynxContextHolder *holder = [self setUpHolder];
  [holder.ui requestAccessibilityFocus:@{@"withoutUpdate" : @(YES)}
                            withResult:^(int code, id _Nullable data) {
                              XCTAssert(code == 0);
                            }];
  [holder.ui requestAccessibilityFocus:nil
                            withResult:^(int code, id _Nullable data) {
                              XCTAssert(code == 0);
                            }];
  XCTAssert([holder.ui accessibilityFocusedView] == holder.ui.view);
}

- (void)testFetchAccessibilityTargets {
  LynxContextHolder *holder = [self setUpHolder];
  [holder.ui
      fetchAccessibilityTargets:nil
                     withResult:^(int code, NSArray *_Nullable data) {
                       XCTAssert(code == 0);
                       XCTAssert([@"unknown" isEqualToString:[data[0] objectForKey:@"a11y-id"]]);
                       XCTAssert([@(1) isEqualToNumber:[data[0] objectForKey:@"element-id"]]);
                     }];
  LynxUI *child = [[LynxUI alloc] initWithView:[[UIView alloc] init]];
  child.sign = 22;
  child.a11yID = @"22";
  [holder.ui insertChild:child atIndex:0];
  [holder.ui
      fetchAccessibilityTargets:nil
                     withResult:^(int code, NSArray *_Nullable data) {
                       XCTAssert(code == 0);
                       XCTAssert([@"22" isEqualToString:[data[1] objectForKey:@"a11y-id"]]);
                       XCTAssert([@(22) isEqualToNumber:[data[1] objectForKey:@"element-id"]]);
                     }];
}

- (void)testInnerText {
  LynxContextHolder *holder = [self setUpHolder];
  LynxUIText *child = [[LynxUIText alloc] init];
  LynxLayoutSpec *spec = [[LynxLayoutSpec alloc] init];
  [child onReceiveUIOperation:[[LynxTextRenderer alloc]
                                  initWithAttributedString:[[NSAttributedString alloc]
                                                               initWithString:@"hello"]
                                                layoutSpec:spec]];
  [holder.ui insertChild:child atIndex:0];

  LynxUIText *child2 = [[LynxUIText alloc] init];
  [child2 onReceiveUIOperation:[[LynxTextRenderer alloc]
                                   initWithAttributedString:[[NSAttributedString alloc]
                                                                initWithString:@"lynx"]
                                                 layoutSpec:spec]];
  [holder.ui insertChild:child2 atIndex:1];
  [holder.ui innerText:nil
            withResult:^(int code, id _Nullable data) {
              XCTAssert(code == 0);
              XCTAssert([@"hello" isEqualToString:data[0]]);
              XCTAssert([@"lynx" isEqualToString:data[1]]);
            }];
}

- (void)testAccessibilityElementsWithA11yID {
  LynxContextHolder *holder = [self setUpHolder];
  LynxUI *child1 = [[LynxUI alloc] initWithView:[[UIView alloc] init]];
  child1.sign = 11;
  child1.a11yID = @"a11y_11";
  [holder.ui insertChild:child1 atIndex:0];
  [holder.context.rootView addView:child1.view forA11y:child1.a11yID];
  [holder.context.rootView addLynxUI:child1 forIndex:child1.sign];

  LynxUI *child11 =
      [[LynxUI alloc] initWithView:[[UIView alloc] initWithFrame:CGRectMake(1, 0, 1, 5)]];
  child11.sign = 111;
  child11.a11yID = @"a11y_same";
  [child1 insertChild:child11 atIndex:0];
  [holder.context.rootView addView:child11.view forA11y:child11.a11yID];
  [holder.context.rootView addLynxUI:child11 forIndex:child11.sign];

  LynxUI *child2 =
      [[LynxUI alloc] initWithView:[[UIView alloc] initWithFrame:CGRectMake(2, 0, 1, 3)]];
  child2.sign = 12;
  child2.a11yID = @"a11y_12";
  [holder.ui insertChild:child2 atIndex:1];
  [holder.context.rootView addView:child2.view forA11y:child2.a11yID];
  [holder.context.rootView addLynxUI:child2 forIndex:child2.sign];

  LynxUI *child12 =
      [[LynxUI alloc] initWithView:[[UIView alloc] initWithFrame:CGRectMake(3, 0, 1, 2)]];
  child12.sign = 121;
  child12.a11yID = @"a11y_same";
  [child2 insertChild:child12 atIndex:0];
  [holder.context.rootView addView:child12.view forA11y:child12.a11yID];
  [holder.context.rootView addLynxUI:child12 forIndex:child12.sign];

  LynxUI *childSpecial =
      [[LynxUI alloc] initWithView:[[UIView alloc] initWithFrame:CGRectMake(4, 0, 1, 4)]];
  childSpecial.sign = 233;
  childSpecial.a11yID = @"a11y_same";
  [holder.ui insertChild:childSpecial atIndex:0];
  [holder.context.rootView addView:childSpecial.view forA11y:childSpecial.a11yID];
  [holder.context.rootView addLynxUI:childSpecial forIndex:childSpecial.sign];

  [LynxPropsProcessor updateProp:@"a11y_same,12,11,233"
                         withKey:@"accessibility-elements-a11y"
                           forUI:holder.ui];
  NSArray *array = [holder.ui accessibilityElementsWithA11yID];
  XCTAssert(array[0] == child11.view);
  XCTAssert(array[1] == child12.view);
  XCTAssert(array[2] == child2.view);
  XCTAssert(array[3] == child1.view);
  XCTAssert(array[4] == childSpecial.view);
}

@end
