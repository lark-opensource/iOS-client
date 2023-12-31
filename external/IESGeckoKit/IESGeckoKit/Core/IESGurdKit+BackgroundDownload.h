//
//  IESGurdKit+BackgroundDownload.h
//  Indexer
//
//  Created by bytedance on 2021/10/13.
//

#import "IESGeckoKit.h"

typedef NS_ENUM(NSInteger,IESGurdDownloadPolicy) {
    IESGurdDownloadPolicyDefault = 0,
    IESGurdDownloadPolicyBackgroundOnly,   // 只能后台下载
    IESGurdDownloadPolicyImmediatelyInActive,  // 重新进入前台立即下载
};

@interface IESGurdKit (BackgroundDownload)

@property (class, nonatomic, assign) IESGurdDownloadPolicy downloadPolicy;

@property (class, nonatomic, assign) BOOL background;

@property (class, nonatomic, copy) NSArray<NSString *> *backgroundAccessKeys;

+ (BOOL)useDownloadDelegate;

@end

