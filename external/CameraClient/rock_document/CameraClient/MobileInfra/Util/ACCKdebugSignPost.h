//
//  ACCKdebugSignPost.h
//  CameraClient-Pods-Aweme
//
//  Created by 刘兵 on 2019/12/23.
//

#ifndef ACCKdebugSignPost_h
#define ACCKdebugSignPost_h

#ifdef DEBUG
#import <sys/kdebug_signpost.h>

#define ACCKdebugSignPost(code, arg1, arg2, arg3, arg4) \
if (@available(iOS 10.0, *)) { \
      kdebug_signpost(code, arg1, arg2, arg3, arg4); \
} \

#define ACCKdebugSignPostStart(code, arg1, arg2, arg3, arg4) \
if (@available(iOS 10.0, *)) { \
      kdebug_signpost_start(code, arg1, arg2, arg3, arg4); \
} \

#define ACCKdebugSignPostEnd(code, arg1, arg2, arg3, arg4) \
if (@available(iOS 10.0, *)) { \
      kdebug_signpost_end(code, arg1, arg2, arg3, arg4); \
} \

#else

#define ACCKdebugSignPost(code, arg1, arg2, arg3, arg4)

#define ACCKdebugSignPostStart(code, arg1, arg2, arg3, arg4)

#define ACCKdebugSignPostEnd(code, arg1, arg2, arg3, arg4)

#endif

#endif
