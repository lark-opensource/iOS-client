//
//  DVEImageMacro.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/11/22.
//

#ifndef DVEImageMacro_h
#define DVEImageMacro_h

#import "DVECustomResourceProvider.h"

#pragma mark - Common

FOUNDATION_STATIC_INLINE UIImage * DVEImageWithName(NSString *name)
{
    return [[DVECustomResourceProvider shareManager] imageWithName:name];
}

#endif /* DVEImageMacro_h */
