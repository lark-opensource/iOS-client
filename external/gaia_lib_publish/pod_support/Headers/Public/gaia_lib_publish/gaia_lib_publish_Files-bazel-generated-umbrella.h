#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "Gaia/Files/AMGArchive.h"
#import "Gaia/Files/AMGFile.h"
#import "Gaia/Files/AMGFileDescriptor.h"
#import "Gaia/Files/AMGFileHandle.h"
#import "Gaia/Files/AMGFileHandleGeneric.h"
#import "Gaia/Files/AMGFileReader.h"
#import "Gaia/Files/AMGFileUtils.h"
#import "Gaia/Files/AMGFileWriter.h"
#import "Gaia/Files/AMGMemoryReader.h"
#import "Gaia/Files/AMGMemoryStream.h"
#import "Gaia/Files/AMGMemoryWriter.h"

FOUNDATION_EXPORT double gaia_lib_publishVersionNumber;
FOUNDATION_EXPORT const unsigned char gaia_lib_publishVersionString[];