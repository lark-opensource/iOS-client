//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "BDXLynxOverlayGlobalManager.h"

/**
 * Implement BDXLynxOverlayGlobalContainer to customize hitTest
 */
@interface BDXLynxOverlayGlobalContainer : UIView

@end


@implementation BDXLynxOverlayGlobalContainer

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  NSEnumerator *enumerator = [self.subviews reverseObjectEnumerator];
  UIView *subview = nil;
  
  // enumerate subviews reversely to dispatch hitTest from upper level to lower level
  while (subview = [enumerator nextObject]) {
    if (!subview.hidden) {
      UIView *view = [subview hitTest:point withEvent:event];
      if (view) {
        return view;
      }
    }
  }
  return nil;
}


@end


@interface BDXLynxOverlayGlobalManager ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableDictionary<NSNumber *, UIView *> *> *levelContainers;

@end

@implementation BDXLynxOverlayGlobalManager

+ (instancetype)sharedInstance {
  static BDXLynxOverlayGlobalManager *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[BDXLynxOverlayGlobalManager alloc] init];
    instance.levelContainers = [NSMutableDictionary dictionary];
  });
  return instance;
}

+ (NSMutableArray*)getAllVisibleOverlay {
  NSMutableArray* array = [NSMutableArray array];
  NSMutableDictionary<NSNumber *, NSMutableDictionary<NSNumber *, UIView *> *>* levelContainers = BDXLynxOverlayGlobalManager.sharedInstance.levelContainers;
  for (id key in levelContainers) {
    NSMutableDictionary* allLevelContainerAtTheMode = levelContainers[key];
      NSArray *sortKey = [[allLevelContainerAtTheMode allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull levelLeft, id  _Nonnull levelRight) {
        NSInteger integerLevelLeft = [levelLeft integerValue];
        NSInteger integerLevelRight = [levelRight integerValue];
    
        if (integerLevelLeft > integerLevelRight) {
             return (NSComparisonResult)NSOrderedAscending;
        }
        if (integerLevelLeft < integerLevelRight) {
             return (NSComparisonResult)NSOrderedDescending;
        }
        return (NSComparisonResult)NSOrderedSame;
      }];
    [sortKey enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      UIView *levelContainer = allLevelContainerAtTheMode[obj];
      BDXLynxOverlayLightContainer* overlayView = levelContainer.subviews[0];
      if (!overlayView.hidden) {
        [array addObject:[NSNumber numberWithInteger:overlayView.uiDelegate.getSign]];
      }
    }];
  }
  return array;
}

- (UIView *)getTopViewControllerWithMode:(BDXLynxOverlayLightMode)mode
                               customViewController:(UIViewController *)customViewController{
  UIView *topContainer = nil;
  switch (mode) {
    case BDXLynxOverlayLightModeWindow:
      topContainer = [self windowContainer];
      break;
    case BDXLynxOverlayLightModeTopController:
      topContainer = [self topContainer];
      break;
    case BDXLynxOverlayLightModeCustom:
      if ([customViewController isKindOfClass:UIViewController.class]) {
        topContainer = customViewController.view;
      } else if ([customViewController isKindOfClass:UIView.class]) {
        topContainer = (UIView *)customViewController;
      } else {
        topContainer = [self windowContainer];
      }
      break;
    default:
      topContainer = [self pageContainer];
      break;
  }
  return topContainer;
}

- (void)destoryOverlayView:(UIView *)overlay atLevel:(NSInteger)level withMode:(BDXLynxOverlayLightMode)mode customViewController:(UIViewController *)customViewController {
  // Firstly, get the top container by the mode
 
  UIView *topContainer = [self getTopViewControllerWithMode:mode customViewController:customViewController];
    
  NSInteger identifier = [self identifierWithModel:mode withContainer:topContainer];

  NSMutableDictionary *allLevelContainerAtTheMode = self.levelContainers[@(identifier)];
  
  UIView *view = allLevelContainerAtTheMode[@(level)];
  
  [allLevelContainerAtTheMode removeObjectForKey:@(level)];
  
  if (allLevelContainerAtTheMode.count == 0) {
    [self.levelContainers removeObjectForKey:@(identifier)];
  }
  
  [view removeFromSuperview];
  
  [overlay removeFromSuperview];
}


- (UIView *)showOverlayView:(UIView *)overlay atLevel:(NSInteger)level withMode:(BDXLynxOverlayLightMode)mode customViewController:(UIViewController *)customViewController {
  // Firstly, get the top container by the mode
  UIView *topContainer = [self getTopViewControllerWithMode:mode customViewController:customViewController];
  
  // Secondly, get the level container inside the top container with the specific level
  UIView *levelContainer = [self levelContainerAt:level withModel:mode withContainer:topContainer];
  
  // Thirdly, add the OverlayView to the level container
  if (levelContainer != overlay.superview) {
    [overlay removeFromSuperview];
    [levelContainer addSubview:overlay];
  }
  if (levelContainer.superview != topContainer) {
    [levelContainer removeFromSuperview];
    [topContainer addSubview:levelContainer];
  }
  
  // Finally, sort all the views inside the top container, because we may insert a new level
  [self sortViewsWithModel:mode withContainer:topContainer];
  return topContainer;
}


- (UIView *)levelContainerAt:(NSInteger)level withModel:(BDXLynxOverlayLightMode)mode withContainer:(UIView *)topContainer {
    NSInteger identifier = [self identifierWithModel:mode withContainer:topContainer];

  if (!self.levelContainers[@(identifier)]) {
    self.levelContainers[@(identifier)] = [NSMutableDictionary dictionary];
  }
  
  NSMutableDictionary *allLevelContainerAtTheMode = self.levelContainers[@(identifier)];
  if (!allLevelContainerAtTheMode) {
    allLevelContainerAtTheMode = [NSMutableDictionary dictionary];
    self.levelContainers[@(identifier)] = allLevelContainerAtTheMode;
  }
  
  if (!allLevelContainerAtTheMode[@(level)]) {
    UIView *view = [[BDXLynxOverlayGlobalContainer alloc] initWithFrame:UIScreen.mainScreen.bounds];
    allLevelContainerAtTheMode[@(level)] = view;
    [topContainer addSubview:view];
  }
  return allLevelContainerAtTheMode[@(level)];
}

/**
 * Rearrange all subviews inside topContainer by level
 */
- (void)sortViewsWithModel:(BDXLynxOverlayLightMode)mode withContainer:(UIView *)topContainer {
    NSInteger identifier = [self identifierWithModel:mode withContainer:topContainer];

  NSMutableDictionary *allLevelContainerAtTheMode = self.levelContainers[@(identifier)];
  NSArray *sortKey = [[allLevelContainerAtTheMode allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull levelLeft, id  _Nonnull levelRight) {
    NSInteger integerLevelLeft = [levelLeft integerValue];
    NSInteger integerLevelRight = [levelRight integerValue];

    if (integerLevelLeft > integerLevelRight) {
         return (NSComparisonResult)NSOrderedAscending;
    }
    if (integerLevelLeft < integerLevelRight) {
         return (NSComparisonResult)NSOrderedDescending;
    }
    return (NSComparisonResult)NSOrderedSame;
  }];

  
  [sortKey enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    UIView *levelContainer = allLevelContainerAtTheMode[obj];
    [topContainer bringSubviewToFront:levelContainer];
  }];
}

/**
 * Generate identifier to identify the container instance at specified mode
 */
- (NSInteger)identifierWithModel:(BDXLynxOverlayLightMode)mode withContainer:(UIView *)container {
    return mode + (uintptr_t)container;
}



- (UIView *)modalContainer {
  UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
  while (topController.presentedViewController) {
    topController = topController.presentedViewController;
  }
  return topController.view;
}

- (UIView *)topContainer {
  UIViewController *topController;
  UIViewController *rootController = [UIApplication sharedApplication].keyWindow.rootViewController;
  if ([rootController isKindOfClass:UINavigationController.class]) {
    topController = ((UINavigationController *)rootController).topViewController ? : rootController;
  } else {
    topController = rootController.navigationController.topViewController ? : rootController;
  }
  return topController.view;
}

- (UIView *)pageContainer {
  UIViewController *topController;
  UIViewController *rootController = [UIApplication sharedApplication].keyWindow.rootViewController;
  if ([rootController isKindOfClass:UINavigationController.class]) {
    topController = ((UINavigationController *)rootController);
  } else {
    topController = rootController.navigationController ? : rootController;
  }
  return topController.view;
}

- (UIView *)windowContainer {
  return UIApplication.sharedApplication.keyWindow;
}

@end
