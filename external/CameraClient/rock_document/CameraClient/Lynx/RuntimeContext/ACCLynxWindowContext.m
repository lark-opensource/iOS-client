//
//  ACCLynxWindowContext.m
//  Indexer
//
//  Created by wanghongyu on 2021/11/9.
//

#import "ACCLynxWindowContext.h"

@interface ACCLynxWindowContext ()

@property (nonatomic, strong) NSPointerArray *windowStack;
@property (nonatomic, strong) NSPointerArray *lynxStack;
@property (nonatomic, strong) NSMapTable *dismissActionMap;

@end

@implementation ACCLynxWindowContext

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static id sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ACCLynxWindowContext alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _windowStack = [NSPointerArray weakObjectsPointerArray];
        _lynxStack = [NSPointerArray weakObjectsPointerArray];
        _dismissActionMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
    }
    return self;
}

- (void)addContianer:(UIViewController *)contianer {
    if (!contianer) {
        return;
    }
    [self push:contianer to:self.windowStack];
}

- (void)showViewController:(UIViewController *)vc {
    [self showViewController:vc dismissAction:nil];
}

- (void)showViewController:(UIViewController *)vc dismissAction:(dispatch_block_t)dismissAction {
    if (!vc) {
        return;
    }
    if (dismissAction != nil) {
        [self.dismissActionMap setObject:dismissAction forKey:vc];
    }
    UIViewController *topVC = [self last:self.windowStack];
    [self push:vc to:self.lynxStack];
    [topVC addChildViewController:vc];
    [topVC.view addSubview:vc.view];
}

- (void)showViewController:(UIViewController *)vc frame:(CGRect)frame {
    if (!vc) {
        return;
    }
    UIViewController *topVC = [self last:self.windowStack];
    [self push:vc to:self.lynxStack];
    [topVC addChildViewController:vc];
    vc.view.frame = frame;
    [topVC.view addSubview:vc.view];
}

- (void)dismiss {
    UIViewController *vc = [self last:self.lynxStack];
    [vc.view removeFromSuperview];
    [vc removeFromParentViewController];
    dispatch_block_t action = [self.dismissActionMap objectForKey:vc];
    if (action) {
        action();
    }
}

#pragma mark - util

- (void)push:(UIViewController *)viewcontroller to:(NSPointerArray *)warr {
    [warr addPointer:(__bridge void * _Nullable)viewcontroller];
}

- (UIViewController *)last:(NSPointerArray *)warr {
    [warr addPointer:NULL];
    [warr compact];
    
    if (warr.count == 0) return nil;
    return (__bridge id)[warr pointerAtIndex:warr.count-1];
}

@end
