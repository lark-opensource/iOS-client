//
//  HMDTTLeaksFinderConfig.m
//  Heimdallr_Example
//
//  Created by bytedance on 2020/5/29.
//  Copyright © 2020 ghlsb@hotmail.com. All rights reserved.
//

#import "TTHMDLeaksFinderConfig.h"
#import "TTHMDLeaskFinderTracker.h"
#import <ByteDanceKit/NSString+BTDAdditions.h>

NSString *const kTTHMDModuleLeaksFinderTracker = @"leaks_finder";

#define HMD_ARRAY(key,value) @[@#key,value]

#define HMD_ATTRIBUTE_MAP_DEFAULT(property,key,default) @#property:HMD_ARRAY(key,default)


#ifndef HMD_SECTION_DATA
#define HMD_SECTION_DATA(sectname) __attribute((used, section("__DATA,"#sectname)))
#endif

#ifndef HMD_SECTION_DATA_REGISTER
#define HMD_SECTION_DATA_REGISTER(sectname,name) const char * k_##name##_sectdata HMD_SECTION_DATA(sectname) = #name;
#endif

#ifndef HMD_MODULE_CONFIG
#define HMD_MODULE_CONFIG(name) HMD_SECTION_DATA_REGISTER(HMDModule,name)
#endif

HMD_MODULE_CONFIG(TTHMDLeaksFinderConfig)

@implementation TTHMDLeaksFinderConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
             HMD_ATTRIBUTE_MAP_DEFAULT(doubleSend, double_send, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableNoVcAndViewHook, enable_normal_object_hook, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableAssociatedObjectHook, enable_associated_object_hook, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(classWhitelist, class_white_list, @[]),
             HMD_ATTRIBUTE_MAP_DEFAULT(viewStackType, view_stack_type, @1),
             HMD_ATTRIBUTE_MAP_DEFAULT(filters, filters, @""),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableAlogOpen, enable_alog_open, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableDetectSystemClass, enable_detect_system_class, @0),

             };
}

+ (NSString *)configKey {
    return kTTHMDModuleLeaksFinderTracker;
}

- (id<HeimdallrModule>)getModule {
    return [TTHMDLeaskFinderTracker sharedTracker];
}

- (void)setFilters:(NSString *)filters {
    _filters = [filters copy];
    _filtersDic = [filters btd_jsonDictionary];
}

@end

