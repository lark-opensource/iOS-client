//
//  WKWebView+OKSnapshot.h
//  OKSnapshotScroll
//
//  Created by apple on 16/12/28.
//  Copyright © 2016年 TonyReet. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "UIScrollView+OKSnapshot.h"

@interface WKWebView (OKSnapshot)

- (void )screenSnapshotNeedMask:(BOOL)needMask addMaskAfterBlock:(void(^)(void))addMaskAfterBlock finishBlock:(OKSnapshotFinishBlock )finishBlock;

@end
