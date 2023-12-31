//
//  LVResourceDownloadOperation.h
//  LVResourceDownloader
//
//  Created by xiongzhuang on 2019/8/19.
//

#import <Foundation/Foundation.h>
#import "LVResourceDownloadOperation.h"
#include <player/DefaultResourceFetcher.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVEffectResourceDownloadOperation : LVResourceDownloadOperation

@property (assign, nonatomic) std::shared_ptr<cut::FetchEffectRequest> request;

@end

NS_ASSUME_NONNULL_END
