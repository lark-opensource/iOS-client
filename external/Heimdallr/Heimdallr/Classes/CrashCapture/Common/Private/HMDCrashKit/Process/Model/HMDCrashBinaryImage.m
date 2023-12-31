//
//  HMDCrashBinaryImage.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashBinaryImage.h"

@implementation HMDCrashSection

- (void)updateWithDictionary:(NSDictionary *)dict {
    [super updateWithDictionary:dict];
    self.size = [dict hmd_unsignedLongLongForKey:@"size"];
    self.base = [dict hmd_unsignedLongLongForKey:@"base"];
    self.sectionName = [dict hmd_stringForKey:@"sect_name"];
}

@end

@implementation HMDCrashSegment

- (void)updateWithDictionary:(NSDictionary *)dict {
    [super updateWithDictionary:dict];
    self.size = [dict hmd_unsignedLongLongForKey:@"size"];
    self.base = [dict hmd_unsignedLongLongForKey:@"base"];
    self.segmentName = [dict hmd_stringForKey:@"seg_name"];
    NSArray<NSDictionary *> *sections = [dict hmd_arrayForKey:@"sections"];
    if(sections != nil) {
        self.sections = [HMDCrashSection objectsWithDicts:sections];
    }
}

@end

@implementation HMDCrashBinaryImage

@synthesize name = _name;

- (void)updateWithDictionary:(NSDictionary *)dict {
    [super updateWithDictionary:dict];
    NSDictionary *content = [dict hmd_dictForKey:@"load"];
    if (content) {
        self.load = YES;
    }else{
        content = [dict hmd_dictForKey:@"unload"];
    }
    self.path = [content hmd_stringForKey:@"path"];
    self.size = [content hmd_unsignedLongLongForKey:@"size"];
    self.arch = [content hmd_stringForKey:@"arch"];
    self.base = [content hmd_unsignedLongLongForKey:@"base"];
    self.uuid = [content hmd_stringForKey:@"uuid"];
    self.isMain = [content hmd_boolForKey:@"is_main"];
    self.segments = [HMDCrashSegment objectsWithDicts:[content hmd_arrayForKey:@"segments"]];
    
    NSArray *names = @[@"SubstrateLoader",
                       @"MobileSubstrate",
                       @"TweakInject",
                       @"CydiaSubstrate",
                       @"libsubstrate",
                       @"libhdev"];
    for (NSString *name in names) {
        if ([self.path containsString:name]) {
            self.isEnvAbnormal = YES;
            break;
        }
    }
}

- (NSString *)name {
    if(_name != nil) return _name;
    if(_path == nil) return nil;
    _name = _path.lastPathComponent;
    return _name;
}

- (BOOL)containingAddress:(uintptr_t)address {
    
    if (address >= self.base && address < (self.base + self.size)) {
        return YES;
    }
    
    __block BOOL result = NO;
    [self.segments enumerateObjectsUsingBlock:^(HMDCrashSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (address >= obj.base && address < (obj.base + obj.size)) {
            result = YES;
            *stop = YES;
        }
    }];
    
    return result;
}

- (NSUInteger)hash {
    return _base;
}

- (BOOL)isEqual:(id)object {
    if([object isKindOfClass:HMDCrashBinaryImage.class]) {
        return _base == ((HMDCrashBinaryImage *)object).base;
    }
    return NO;
}

@end
