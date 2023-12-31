
/*!@header HMDCrashLoadLogger.m
   @author somebody
   @abstract Log Status of Crash Load Launch
 */

#include "HMDMacro.h"
#include "HMDCrashLoadLogger.h"
#include "HMDCrashLoadLogger+Path.h"

#ifdef HMD_CLOAD_DEBUG

#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <dispatch/once.h>
#include <objc/runtime.h>
#include <objc/message.h>

#define HMD_CLOAD_LOGGER_STACK_MAX_LENGTH 1024

static void HMDCrashLoadLogger_outputString(const char * _Nonnull string,
                                            size_t stringLength);

void HMDCrashLoadLogger_format(const char * _Nonnull file, int line,
                               const char * _Nonnull format, ...) {
    if(format == NULL) DEBUG_RETURN_NONE;
    
    if(file == NULL) file = "unknownFile";
    
    const char *firstDelimiter = strrchr(file, '/');
    if(firstDelimiter != NULL) file = firstDelimiter + 1;
    
    int prefixLength = snprintf(NULL, 0, "[CrashLoad][%s:%d] ", file, line);
    
    va_list ap1;
    va_start(ap1, format);
    int contentLength = vsnprintf(NULL, 0, format, ap1);
    va_end(ap1);
    
    if(prefixLength < 0 || contentLength < 0)
        DEBUG_RETURN_NONE;
    
    // prefix + content + '\n'
    int fullLength = prefixLength + contentLength + 1;
    
    char * tempWritten = NULL;
    bool needFree = false;
    
    if(fullLength <= HMD_CLOAD_LOGGER_STACK_MAX_LENGTH) {
        tempWritten = __builtin_alloca(fullLength + 1);
    } else {
        tempWritten = malloc(fullLength + 1);
        if(tempWritten == NULL) DEBUG_RETURN_NONE;
        needFree = true;
    }
    
    int shouldMatchPrefixLength =
        snprintf(tempWritten, prefixLength + 1,
                 "[CrashLoad][%s:%d] ", file, line);
    
    va_list ap2;
    va_start(ap2, format);
    int shouldMatchContentLength =
        vsnprintf(tempWritten + prefixLength, contentLength + 1, format, ap2);
    va_end(ap2);
    
    DEBUG_ASSERT(shouldMatchPrefixLength  == prefixLength);
    DEBUG_ASSERT(shouldMatchContentLength == contentLength);
    
    DEBUG_ASSERT(tempWritten[prefixLength + contentLength] == '\0');
    
    tempWritten[prefixLength + contentLength] = '\n';
    tempWritten[prefixLength + contentLength + 1] = '\0';
    
    HMDCrashLoadLogger_outputString(tempWritten, fullLength);
    
    if(needFree) free(tempWritten);
}

NSString * _Nullable HMDCrashLoadLogger_path(NSString * _Nonnull path) {
    if(path == nil) DEBUG_RETURN(nil);
    path = [path stringByStandardizingPath];
    
    static NSString *homePath;
    static NSRange homePathRange;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        homePath = [NSHomeDirectory() stringByStandardizingPath];
        homePathRange = NSMakeRange(0, homePath.length);
    });
    
    if(![path hasPrefix:homePath])
        return path;
    
    path = [path stringByReplacingCharactersInRange:homePathRange
                                         withString:@""];
    
    if([path hasPrefix:@"/"]) {
        
    }
    
    return path;
}

static void HMDCrashLoadLogger_outputString(const char * _Nonnull string,
                                            size_t stringLength) {
    
    static int sharedFileFD = -1;
    static Class sharedClass = nil;
    static SEL sharedSelector = NULL;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd-HH:mm"];
        NSString *dateString = [dateFormatter stringFromDate:NSDate.date];
        
        NSString *fileName =
            [NSString stringWithFormat:@"CLoadLog_%@", dateString];
        
        NSString *relativeFolder =
            @"Library/Heimdallr/CrashCapture/LoadLaunch/Log";
        
        NSString *folderPath =
            [NSHomeDirectory() stringByAppendingPathComponent:relativeFolder];
        
        [NSFileManager.defaultManager createDirectoryAtPath:folderPath
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:nil];
        
        
        NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
        
        // file mode user read write
        int fd = open(filePath.UTF8String, O_RDWR|O_CREAT, 0644);
        
        if(fd > 0) sharedFileFD = fd;
        
        Class aClass = objc_getClass("FCSRWTESTEnvironment");
        if(aClass != nil) {
            SEL aSEL = sel_registerName("crashLoadOutputString:");
            Class metaClass = object_getClass(aClass);
            if(class_respondsToSelector(metaClass, aSEL)) {
                sharedClass = aClass;
                sharedSelector = aSEL;
            }
        }
    });
    
    // call placeholder
    if(sharedClass != nil) {
        ((void(*)(Class, SEL, const char *))objc_msgSend)
            (sharedClass, sharedSelector, string);
    }
    
    // write to file
    if(sharedFileFD >= 0) {
        
        const uint8_t * buf = (uint8_t *)string;
        ssize_t length = stringLength;
        
        ssize_t written = 0;
        int error_count = 0;
        do {
            ssize_t write_bytes =
                write(sharedFileFD, (uint8_t *)buf + written, length - written);
            if(write_bytes >= 0) {
                written += write_bytes;
                error_count = 0;
            } else {
                error_count += 1;
                DEBUG_ASSERT(error_count <= 3);
                if (error_count > 3) {
                    break;
                }
            }
        } while (written < length);
    }
    
    // stderr
    fputs(string, stderr);
}

#endif /* HMD_CLOAD_DEBUG */
