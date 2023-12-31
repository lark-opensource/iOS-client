//
//  IESGurdDownloadProgressObject.h
//  IESGeckoKit
//
//  Created by bytedance on 2021/11/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdDownloadProgressObject : NSObject

- (void)startObservingWithProgress:(NSProgress *)downloadProgress;

@end

NS_ASSUME_NONNULL_END
