//
//  HMDCrashAddressAnalysis.m
//  AWECloudCommand-iOS13.0
//
//  Created by yuanzhangjing on 2019/12/1.
//

#import "HMDCrashAddressAnalysis.h"
#import "NSString+HMDCrash.h"

@implementation HMDCrashAddressAnalysis

- (void)updateWithDictionary:(NSDictionary *)dict {
    [super updateWithDictionary:dict];
    if ([dict hmd_hasKey:@"objc"]) {
        self.objectInfo = [HMDCrashAddressObjectInfo objectWithDictionary:[dict hmd_dictForKey:@"objc"]];
    }
    if ([dict hmd_hasKey:@"str_value"]) {
        NSString *str = [dict hmd_stringForKey:@"str_value"];
        self.stringInfo = [str hmdcrash_stringWithHex];
    }
    self.value = (uintptr_t)[dict hmd_unsignedLongLongForKey:@"value"];
}

- (NSDictionary *)postDict {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setObject:@(self.value) forKey:@"value"];
    if (self.image || self.segment || self.section) {
        NSString *content = [NSString stringWithFormat:@"%@.%@.%@",
                             self.image.path.lastPathComponent?:@"",
                             self.segment.segmentName?:@"",
                             self.section.sectionName?:@""];
        [dict hmd_setObject:content forKey:@"image_info"];
    }
    if (self.regionInfo) {
        NSString *content = [NSString stringWithFormat:@"[0x%lx - 0x%lx] %@ %@ %@",
                             self.regionInfo.base,
                             self.regionInfo.base+self.regionInfo.size,
                             self.regionInfo.protectionString?:@"",
                             self.regionInfo.userTagString?:@"",
                             self.regionInfo.shareModeString?:@""];
        [dict hmd_setObject:content forKey:@"map_info"];
    }
    if (self.objectInfo) {
        NSMutableString *content = [NSMutableString string];
        if (self.objectInfo.isObject) {
            [content appendFormat:@"Object <%@: 0x%lx>",self.objectInfo.className,self.value];
        } else if (self.objectInfo.isClass) {
            [content appendFormat:@"Class %@",self.objectInfo.className];
        } else if (self.objectInfo.is_tagpointer) {
            [content appendFormat:@"TaggedPointer 0x%lx",self.value];
        }
        
        if (self.objectInfo.content.length > 0) {
            [content appendFormat:@" Content %@", self.objectInfo.content];
        }
        
        if (self.objectInfo.cf_typeID > 0) {
            [content appendFormat:@" CFTypeID %lu",self.objectInfo.cf_typeID];
        }
        [dict hmd_setObject:content forKey:@"object_info"];
    }
    if (self.stringInfo.length > 0) {
        [dict hmd_setObject:self.stringInfo forKey:@"str_value"];
    }
    return dict;
}

@end
