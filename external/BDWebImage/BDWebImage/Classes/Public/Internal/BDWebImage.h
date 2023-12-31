//
//  BDWebImage.h
//  BDWebImage
//
//  Created by senmiao on 2017/12/21.
//

#ifndef BDWebImage_h
#define BDWebImage_h

#import "BDWebImageToB.h"

// HEIC Support
// #import "BDImageDecoderHeic.h"

// 内部版本可用
#if __has_include("BDWebImage/BDWebImage.h")
#import "BDWebImageMacro.h"
#import "BDImagePerformanceRecoder.h"

// Monitor
#import "BDImageMonitorManager.h"
#import "BDWebImageRequest+TTMonitor.h"

// Download
#import "BDDownloadManager.h"
#import "BDDownloadTask.h"

// Chrome
#if __has_include("BDDownloadChromiumTask.h")
#import "BDDownloadChromiumTask.h"
#endif

// URLSession
#if __has_include("BDDownloadURLSessionManager.h")
#import "BDDownloadURLSessionManager.h"
#import "BDDownloadURLSessionTask.h"
#endif

// BDAlog
#import <BDAlogProtocol/BDAlogProtocol.h>
#endif

#endif /* BDWebImage_h */
