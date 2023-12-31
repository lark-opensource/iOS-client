//
//  BDPComponentManager.m
//  Timor
//
//  Created by 王浩宇 on 2018/11/17.
//

#import "BDPComponentManager.h"
#import <OPFoundation/BDPUtils.h>

@interface BDPComponentManager ()

@property (nonatomic, strong) NSMapTable<NSString *, UIView<BDPComponentViewProtocol> *> *views;

@end

@implementation BDPComponentManager

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
+ (instancetype)sharedManager
{
    static BDPComponentManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BDPComponentManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _views = [[NSMapTable alloc] initWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory capacity:10];
    }
    return self;
}

- (NSInteger)generateComponentID
{
    static NSInteger componentID = 1;
    return componentID++;
}

- (BOOL)insertComponentView:(UIView<BDPComponentViewProtocol> *)view toView:(UIView *)container
{
    // 组件View必须为有效UIView
    if (!view || ![view isKindOfClass:[UIView class]]) {
        BDPLogWarn(@"[BDPlatform] BDPComponentManager cannot insert invalid UIView");
        return NO;
    }
    
    // 组件View需要实现BDPComponentViewProtocol，并且componentID不为0
    if (![view conformsToProtocol:@protocol(BDPComponentViewProtocol)] || !view.componentID) {
        BDPLogWarn(@"[BDPlatform] BDPComponentManager cannot insert component which not conforms @protocol(BDPComponentViewProtocol)");
        return NO;
    }
    
    NSString *componentIDKey = [NSString stringWithFormat:@"%ld", (long)view.componentID];
    if ([self.views objectForKey:componentIDKey]) {
        BDPLogWarn(@"[BDPlatform] BDPComponentManager cannot insert with duplicate view.");
        return NO;
    }
    
    [container addSubview:view];
    [self.views setObject:view forKey:componentIDKey];
    return YES;
}

- (BOOL)removeComponentViewByID:(NSInteger)componentID
{
    // 组件View需要实现BDPComponentViewProtocol，并且componentID不为0
    if (!componentID) {
        return NO;
    }
    
    NSString *componentIDKey = [NSString stringWithFormat:@"%ld", (long)componentID];
    UIView *view = [self findComponentViewByID:componentID];
    
    [view resignFirstResponder];
    [view removeFromSuperview];

    [self.views removeObjectForKey:componentIDKey];
    return YES;
}

- (UIView<BDPComponentViewProtocol> *)findComponentViewByID:(NSInteger)componentID
{
    if (!componentID) {
        return nil;
    }
    
    NSString *componentIDKey = [NSString stringWithFormat:@"%ld", (long)componentID];
    return [self.views objectForKey:componentIDKey];
}

#pragma mark -

- (BOOL)insertComponentView:(UIView<BDPComponentViewProtocol> *)view toView:(UIView *)container stringID:(NSString *)stringID
{
    // 组件View必须为有效UIView
    if (!view || ![view isKindOfClass:[UIView class]]) {
        BDPLogWarn(@"[BDPlatform] BDPComponentManager cannot insert invalid UIView");
        return NO;
    }

    // stringID不能为空
    if (BDPIsEmptyString(stringID)) {
        BDPLogWarn(@"componentID empty");
        return NO;
    }

    if ([self.views objectForKey:stringID]) {
        BDPLogWarn(@"[BDPlatform] BDPComponentManager cannot insert with duplicate view.");
        return NO;
    }

    [container addSubview:view];
    [self.views setObject:view forKey:stringID];
    return YES;
}

- (BOOL)removeComponentViewByStringID:(NSString *)stringID
{
    // stringID不为空
    if (BDPIsEmptyString(stringID)) {
        return NO;
    }

    UIView *view = [self findComponentViewByStringID:stringID];

    [view resignFirstResponder];
    [view removeFromSuperview];

    [self.views removeObjectForKey:stringID];
    return YES;
}

- (UIView *)findComponentViewByStringID:(NSString *)stringID
{
    // stringID不为空
    if (BDPIsEmptyString(stringID)) {
        return nil;
    }

    return [self.views objectForKey:stringID];
}

@end
