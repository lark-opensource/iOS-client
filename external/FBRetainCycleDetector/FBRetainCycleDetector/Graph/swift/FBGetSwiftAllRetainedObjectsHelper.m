//
//  FBGetSwiftAllRetainedObjects.m
//  FBRetainCycleDetector
//
//  Created by  郎明朗 on 2021/5/8.
//

#import <objc/runtime.h>
#import "FBGetSwiftAllRetainedObjectsHelper.h"
#import "FBClassStrongLayout.h"
#import "FBObjectReference.h"
#import "FBRetainCycleAlogDelegate.h"
#import "FBRetainCycleUtils.h"



NSDictionary<NSString *, id> *FBGetStrongReferencesForSwiftClass(Class aCls, id obj, FBObjectGraphConfiguration *configuration) {
    NSArray<id<FBObjectReference>> *strongIvar = FBGetClassOrObjectStrongReferences(aCls,configuration.layoutCache,true);
    NSMutableDictionary *res = [NSMutableDictionary new];
    for (id<FBObjectReference> ref in strongIvar) {
        id referencedObject = [ref objectReferenceFromObject:obj];
        if (referencedObject){
            [res setValue:referencedObject forKey:[[ref namePath] componentsJoinedByString:@" -> "]];
        }
    }
    return res;
}


const char * makeSymbolicMangledNameStringRef(const char *base) {
    if (!base)
      return base;
    
    const char * end = base;
    while (*end != '\0') {
      // Skip over symbolic references.
      if (*end >= '\x01' && *end <= '\x17')
        end += sizeof(uint32_t);
      else if (*end >= '\x18' && *end <= '\x1F')
        end += sizeof(void*);
      ++end;
    }
    return end - base > 1 ? end - 2 : base;
}

void reportAlog(NSString* alog){
    if ([FBRetainCycleAlogDelegate sharedDelegate].delegate && [[FBRetainCycleAlogDelegate sharedDelegate].delegate respondsToSelector:@selector(findInstanceStrongPropertyAlog:)]) {
        [[FBRetainCycleAlogDelegate sharedDelegate].delegate findInstanceStrongPropertyAlog:alog];
    }
}

malloc_zone_t *fb_safe_malloc_zone_from_ptr_swift(const void *ptr){
    return fb_safe_malloc_zone_from_ptr(ptr);
}
