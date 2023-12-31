//
//  FMDBMacros.h
//  FMDB
//
//  Created by bob on 2020/11/27.
//

#ifndef FMDBMacros_h
#define FMDBMacros_h

#ifndef FMDBLog
#if DEBUG
    #define FMDBLog(s, ...) \
    fprintf(stderr, "<%s:%-4d> %s\n", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:(s), ##__VA_ARGS__] UTF8String])
#else
    #define FMDBLog(s, ...)
#endif
#endif


#endif /* FMDBMacros_h */
