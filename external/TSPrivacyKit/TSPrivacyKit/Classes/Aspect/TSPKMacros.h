//
//  TSPKMacros.h
//  iOS15PhotoDemo
//
//  Created by bytedance on 2021/11/2.
//

#ifndef TSPKMacros_h
#define TSPKMacros_h

#define _CONCAT(A, B) A##B
#define CONCAT(A, B) _CONCAT(A, B)

#if !defined(PIC_MODIFIER)
#define PIC_MODIFIER
#endif

#define SYMBOL_NAME(name) CONCAT(__USER_LABEL_PREFIX__, name)
#define SYMBOL_NAME_PIC(name) CONCAT(SYMBOL_NAME(name), PIC_MODIFIER)


#endif /* TSPKMacros_h */
