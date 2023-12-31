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

#import "BDIAPIHandler.h"
#import "BDIDemoAPIs.h"
#import "BDIRPCRequest.h"
#import "BDIRPCResponse.h"
#import "BDIRPCRoute.h"
#import "BDIRPCStatus.h"
#import "BDISocketServer.h"
#import "ShootsAPISocket.h"

FOUNDATION_EXPORT double ShootsAPISocketVersionNumber;
FOUNDATION_EXPORT const unsigned char ShootsAPISocketVersionString[];