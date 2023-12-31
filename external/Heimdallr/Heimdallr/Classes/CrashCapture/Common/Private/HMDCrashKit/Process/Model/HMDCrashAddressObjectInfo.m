//
//  HMDCrashAddressObjectInfo.m
//  AWECloudCommand-iOS13.0
//
//  Created by yuanzhangjing on 2019/12/1.
//

#import "HMDCrashAddressObjectInfo.h"
#import "NSDictionary+HMDJSON.h"
#import "NSArray+HMDJSON.h"

@implementation HMDCrashAddressObjectInfo

- (void)updateWithDictionary:(NSDictionary *)dict {
    [super updateWithDictionary:dict];
    self.cf_typeID = [dict hmd_unsignedLongLongForKey:@"cf_typeID"];
    self.className = [dict hmd_stringForKey:@"class_name"];
    self.isAligned = [dict hmd_boolForKey:@"is_aligned"];
    self.isClass = [dict hmd_boolForKey:@"is_class"];
    self.isObject = [dict hmd_boolForKey:@"is_object"];
    self.isa_value = [dict hmd_unsignedLongLongForKey:@"isa"];
    self.is_tagpointer = [dict hmd_boolForKey:@"is_tagpointer"];
    
    id object = [dict hmd_dictForKey:@"content"];
    if (!object) {
        object = [dict hmd_arrayForKey:@"content"];
    }
    
    if (object) {
        self.content = [object hmd_jsonString];
        return;
    }
    
    if (!object) {
        object = [dict hmd_stringForKey:@"content"];
    }
    
    if (object) {
        self.content = object;
    }
}

@end
