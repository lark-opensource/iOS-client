//
//  SDWebImageManager+Monitor.m
//  BDWebImage
//
//  Created by Lin Yong on 2019/4/10.
//

#import "SDWebImageManager+Monitor.h"
#import <objc/runtime.h>
#import "BDWebImageCompat.h"
#import "BDImageMonitor+Private.h"
#import "BDImageMonitorManager.h"

@implementation SDWebImageManager(Monitor)
+ (void)load
{
    BDWebImageMethodSwizzle(self,
                            @selector(loadImageWithURL:options:progress:completed:),
                            @selector(bdWebImage_loadImageWithURL:options:progress:completed:));
}

- (BDImageMonitor *)bdWebImage_monitor {
    return [SDWebImageManager monitor];
}

- (id <SDWebImageOperation>)bdWebImage_loadImageWithURL:(nullable NSURL *)url
                                     options:(SDWebImageOptions)options
                                    progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                                   completed:(nullable SDInternalCompletionBlock)completedBlock {
    [[self bdWebImage_monitor] start:[NSString stringWithFormat:@"%@%@", url, @"startReq"]];
    
    __weak typeof(self)weakSelf = self;
    return [self bdWebImage_loadImageWithURL:url
                                     options:options
                                    progress:progressBlock
                                   completed:^(UIImage * _Nullable image,
                                               NSData * _Nullable data,
                                               NSError * _Nullable error,
                                               SDImageCacheType cacheType,
                                               BOOL finished,
                                               NSURL * _Nullable imageURL) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [SDWebImageManager endSDWebImageReqAndReport:imageURL monitor:[strongSelf bdWebImage_monitor]];
        
        if (completedBlock) {
            completedBlock(image, data, error, cacheType, finished, imageURL);
        }
    }];
}

#pragma mark -Monitor

+ (BDImageMonitor *)monitor {
    static BDImageMonitor *monitor = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        monitor = [[BDImageMonitor alloc] initWithModule:@"sdwebimage" action:@"monitor"];
    });
    return monitor;
}

+ (void)endSDWebImageReqAndReport:(nullable NSURL *)url monitor:(BDImageMonitor *)monitor {
    NSMutableDictionary *attributes = [[monitor removeDataForKey:url.absoluteString] mutableCopy];
    double wholeDuration = [monitor stop:[url.absoluteString stringByAppendingString:@"startReq"]];
    if (attributes) {
        [attributes setValue:@(wholeDuration) forKey:@"image_duration"];
        [BDImageMonitorManager trackService:@"sdimage_performance_monitor" status:1 extra:attributes];
    }
}


@end
