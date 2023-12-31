//
//  BDPAppPage+BDPTextArea.m
//  Timor
//
//  Created by lixiaorui on 2020/7/23.
//

#include "BDPAppPage+BDPTextArea.h"
#import "BDPAppPage.h"
#import <objc/runtime.h>


@implementation BDPAppPage (BDPTextArea)

- (void)setBap_lockFrameForEditing:(BOOL)lockFrameForEditing {
    objc_setAssociatedObject(self, @selector(bap_lockFrameForEditing), @(lockFrameForEditing), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)bap_lockFrameForEditing {
    return [(NSNumber *)objc_getAssociatedObject(self, @selector(bap_lockFrameForEditing)) boolValue];
}

@end
