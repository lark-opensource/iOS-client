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

#import "CAKBaseServiceContainer+Loading.h"
#import "CAKLoadingImpl.h"
#import "CAKLoadingView.h"
#import "CAKTextLoadingView.h"

FOUNDATION_EXPORT double CreativeAlbumKitVersionNumber;
FOUNDATION_EXPORT const unsigned char CreativeAlbumKitVersionString[];