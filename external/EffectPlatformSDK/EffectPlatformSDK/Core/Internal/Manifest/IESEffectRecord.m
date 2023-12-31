//
//  IESEffectRecord.m
//  EffectPlatformSDK-Pods
//
//  Created by pengzhenhuan on 2020/9/2.
//

#import "IESEffectRecord.h"

@interface IESEffectRecord ()

@property (nonatomic, copy, readwrite) NSString *effectMD5; // Primary property

@property (nonatomic, copy, readwrite) NSString *effectIdentifier;

@property (nonatomic, assign, readwrite) unsigned long long size;

@property (nonatomic, copy, readwrite) NSString *panel;

@end

@implementation IESEffectRecord

- (instancetype)initWithEffectMD5:(NSString *)effectMD5
                 effectIdentifier:(NSString *)effectIdentifier
                             size:(unsigned long long)size {
    if (self = [super init]) {
        _effectMD5 = [effectMD5 copy];
        _effectIdentifier = [effectIdentifier copy];
        _size = size;
    }
    return self;
}

- (void)updatePanelName:(NSString *)panel {
    self.panel = panel;
}


@end
