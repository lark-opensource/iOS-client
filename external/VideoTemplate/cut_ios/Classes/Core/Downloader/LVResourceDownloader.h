//
//  LVResourceDownloader.h
//  LVResourceDownloader
//
//  Created by xiongzhuang on 2019/8/19.
//

#import <Foundation/Foundation.h>
#include <player/DefaultResourceFetcher.h>
NS_ASSUME_NONNULL_BEGIN
class FetchEffectRequest;
typedef void(^LVDownloadResourceCallback)(BOOL success, NSError * _Nullable error);

typedef void(^LVDownloadResourceProgressCallback)(CGFloat progress);
@interface LVResourceDownloader : NSObject

- (void)downloadResources:(const std::vector<std::shared_ptr<cut::FetchEffectRequest>>&)requests
          progressHandler:(LVDownloadResourceProgressCallback)progressHandler
                 callback:(LVDownloadResourceCallback)callback;

- (void)cancelAllRequest;

@end

NS_ASSUME_NONNULL_END
