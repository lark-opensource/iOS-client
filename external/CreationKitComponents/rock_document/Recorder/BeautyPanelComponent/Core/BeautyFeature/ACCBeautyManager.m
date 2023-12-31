//
//  ACCBeautyManager.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/16.
//

#import "ACCBeautyManager.h"

@interface ACCBeautyManager ()
@property (nonatomic, assign, readwrite) BOOL hasDetectMale;
@property (nonatomic, strong, readwrite) AWEComposerBeautyEffectViewModel *composerEffectVM;
@end


@implementation ACCBeautyManager

+ (instancetype)defaultManager {
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _hasDetectMale = NO;
    }
    return self;
}

- (void)resetWhenQuitRecoder
{
    [self setHasDetectMale:NO];
    [self setComposerEffectVM:nil];
}

- (void)setHasDetectMale:(BOOL)hasDetectMale
{
    if (_hasDetectMale != hasDetectMale) {
        _hasDetectMale = hasDetectMale;
    }
}

- (void)setComposerEffectVM:(AWEComposerBeautyEffectViewModel *)composerEffectVM
{
    _composerEffectVM = composerEffectVM;
}

@end
