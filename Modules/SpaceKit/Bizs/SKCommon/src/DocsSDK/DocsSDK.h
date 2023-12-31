//
//  SpaceKit.h
//  SpaceKit
//
//  Created by Songwen Ding on 2017/12/19.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

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

//! Project version number for DocsSDK.
FOUNDATION_EXPORT double DocsSDKVersionNumber;

//! Project version string for DocsSDK.
FOUNDATION_EXPORT const unsigned char DocsSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DocsSDK/PublicHeader.h>

#import <React/RCTBridgeModule.h>
