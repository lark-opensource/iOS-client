//
//   DVEStringMacro.h
//   Pods
//
//   Created  by ByteDance on 2022/2/24.
//   Copyright © 2022 ByteDance Ltd. All rights reserved.
//
    

#ifndef DVEStringMacro_h
#define DVEStringMacro_h

#import "DVECustomResourceProvider.h"


FOUNDATION_STATIC_INLINE  NSString* DVEStringWithKey(NSString *name, NSString *placeholder)
{
    NSString* value = [[DVECustomResourceProvider shareManager] stringWithName:name];
    if([value isEqualToString:name]){
        return placeholder;
    }
    return value;
}


#endif /* DVEStringMacro_h */
