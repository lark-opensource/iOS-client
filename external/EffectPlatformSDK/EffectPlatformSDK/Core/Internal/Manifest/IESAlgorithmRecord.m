//
//  IESAlgorithmRecord.m
//  EffectPlatformSDK-Pods
//
//  Created by pengzhenhuan on 2020/9/2.
//

#import "IESAlgorithmRecord.h"


@interface IESAlgorithmRecord ()

@property (nonatomic, copy, readwrite) NSString *name; // Primary property

@property (nonatomic, copy, readwrite) NSString *version;

@property (nonatomic, copy, readwrite) NSString *modelMD5;

@property (nonatomic, copy, readwrite) NSString *filePath;

@property (nonatomic, assign, readwrite) unsigned long long size;

@end

@implementation IESAlgorithmRecord

- (instancetype)initWithName:(NSString *)name
                     version:(NSString *)version
                    modelMD5:(NSString *)modelMD5
                    filePath:(NSString *)filePath
                        size:(unsigned long long)size
                    sizeType:(NSInteger)sizeType
{
    if (self = [super init]) {
        _name = [name copy];
        _version = [version copy];
        _modelMD5 = [modelMD5 copy];
        _filePath = [filePath copy];
        _size = size;
        _sizeType = sizeType;
    }
    return self;
}

@end
