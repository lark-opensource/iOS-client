//
//  FBGetSwiftAllRetainedObjects.h
//  FBRetainCycleDetector
//
//  Created by  郎明朗 on 2021/5/8.
//
#import "FBObjectGraphConfiguration.h"
#import <malloc/malloc.h>

NSDictionary<NSString *, id> *FBGetStrongReferencesForSwiftClass(Class aCls,id obj,FBObjectGraphConfiguration *configuration);

const char * makeSymbolicMangledNameStringRef(const char *base);

void reportAlog(NSString* alog);
malloc_zone_t *fb_safe_malloc_zone_from_ptr_swift(const void *ptr);

