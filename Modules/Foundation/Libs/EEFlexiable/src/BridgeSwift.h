//
//  BridgeSwift.h
//  EEFlexiable
//
//  Created by qihongye on 2019/2/11.
//

#ifndef Bridge_h
#define Bridge_h
#import "types.h"

@interface NSValue (CSSValue)

+ (instancetype)valuewithCSSValue:(CSSValue)value;

@property (readonly) CSSValue cssValue;

@end

#endif /* Bridge_h */
