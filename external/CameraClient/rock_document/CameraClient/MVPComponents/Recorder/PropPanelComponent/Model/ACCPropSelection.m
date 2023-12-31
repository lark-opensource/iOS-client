//
//  ACCPropSelection.m
//  CameraClient
//
//  Created by Shen Chen on 2020/5/14.
//

#import "ACCPropSelection.h"

@implementation ACCPropSelection

- (instancetype)initWithEffect:(IESEffectModel *)effect childEffect:(IESEffectModel *)childEffect source:(ACCPropSelectionSource)source
{
    self = [super init];
    if (self) {
        _effect = effect;
        _childEffect = childEffect;
        _source = source;
    }
    return self;
}

- (instancetype)initWithEffect:(IESEffectModel *)effect composerEffect:(id<AWEComposerEffectProtocol>)composerEffect source:(ACCPropSelectionSource)source
{
    self = [super init];
    if (self) {
        _effect = effect;
        _composerEffect = composerEffect;
        _source = source;
    }
    return self;
}

- (instancetype)initWithEffect:(IESEffectModel *)effect source:(ACCPropSelectionSource)source
{
    self = [super init];
    if (self) {
        _effect = effect;
        _source = source;
    }
    return self;
}

- (IESEffectModel *)leafEffect
{
    return self.effect ?: self.childEffect;
}

@end
