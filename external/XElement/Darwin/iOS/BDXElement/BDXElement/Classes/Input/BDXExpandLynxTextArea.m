//
//  BDXExpandLynxTextArea.m
//  BDXElement
//
//  Created by li keliang on 2020/8/9.
//

#import "BDXExpandLynxTextArea.h"

@implementation BDXExpandLynxTextArea

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-textarea")
#else
LYNX_REGISTER_UI("x-textarea")
#endif

@end
