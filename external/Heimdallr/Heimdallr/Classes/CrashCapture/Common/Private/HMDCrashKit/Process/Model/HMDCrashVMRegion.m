//
//  HMDCrassAddressVMRegion.m
//  AWECloudCommand-iOS13.0
//
//  Created by yuanzhangjing on 2019/12/1.
//

#import "HMDCrashVMRegion.h"
#import "HMDCrashVMRegionDescription.h"
@implementation HMDCrashVMRegion

- (void)updateWithDictionary:(NSDictionary *)dict {
    [super updateWithDictionary:dict];
    self.user_tag = [dict hmd_unsignedIntForKey:@"user_tag"];
    self.base = [dict hmd_unsignedLongLongForKey:@"base"];
    self.size = [dict hmd_unsignedLongLongForKey:@"size"];
    self.resident_size = [dict hmd_unsignedLongLongForKey:@"resident_size"];
    self.dirty_size = [dict hmd_unsignedLongLongForKey:@"dirty_size"];
    self.swapped_size = [dict hmd_unsignedLongLongForKey:@"swapped_size"];
    self.protection = [dict hmd_intForKey:@"protection"];
    self.max_protection = [dict hmd_intForKey:@"max_protection"];
    self.share_mode = [dict hmd_intForKey:@"share_mode"];
    self.external_pager = [dict hmd_intForKey:@"external_pager"];
    self.file = [dict hmd_stringForKey:@"file"];
    const char *str = hmd_vm_region_user_tag_string(self.user_tag);
    if (str) {
        self.userTagString = @(str);
    }
    const char *sm = hmd_vm_region_share_mode_string(self.share_mode);
    if (sm) {
        self.shareModeString = @(sm);
    }
    
    self.protectionString = [NSString stringWithFormat:@"%@/%@",[self protectionString:self.protection],[self protectionString:self.max_protection]];
}

- (NSString *)protectionString:(vm_prot_t)protection {
    NSString *str = [NSString stringWithFormat:@"%@%@%@",(protection&VM_PROT_READ)?@"r":@"-",(protection&VM_PROT_WRITE)?@"w":@"-",(protection&VM_PROT_EXECUTE)?@"x":@"-"];
    return str;
}

- (NSDictionary *)postDict {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setObject:@(self.user_tag) forKey:@"user_tag"];
    [dict hmd_setObject:@(self.base) forKey:@"base"];
    [dict hmd_setObject:@(self.size) forKey:@"size"];
    [dict hmd_setObject:@(self.resident_size) forKey:@"resident_size"];
    [dict hmd_setObject:@(self.dirty_size) forKey:@"dirty_size"];
    [dict hmd_setObject:@(self.swapped_size) forKey:@"swapped_size"];
    [dict hmd_setObject:@(self.share_mode) forKey:@"share_mode"];
    [dict hmd_setObject:@(self.protection) forKey:@"protection"];
    [dict hmd_setObject:@(self.max_protection) forKey:@"max_protection"];

    NSString *protectionString = [NSString stringWithFormat:@"%@/%@",[self protectionString:self.protection],[self protectionString:self.max_protection]];
    [dict hmd_setObject:protectionString forKey:@"prot_desc"];
    [dict hmd_setObject:self.userTagString forKey:@"tag_desc"];
    [dict hmd_setObject:self.shareModeString forKey:@"sm_desc"];
    
    if (self.image || self.segment) {
        [dict hmd_setObject:self.image.path.lastPathComponent forKey:@"image_name"];
        [dict hmd_setObject:self.segment.segmentName forKey:@"seg_name"];
    }
    
    [dict hmd_setObject:self.file forKey:@"file"];

    return dict;
}

@end
