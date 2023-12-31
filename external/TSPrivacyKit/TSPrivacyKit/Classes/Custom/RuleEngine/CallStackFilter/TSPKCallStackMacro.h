//
//  TSPKCallStackMacro.h
//  Pods
//
//  Created by bytedance on 2022/7/21.
//

#ifndef TSPKCallStackMacro_h
#define TSPKCallStackMacro_h

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

#endif /* TSPKCallStackMacro_h */
