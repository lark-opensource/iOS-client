//
//  IESGurdTTDownloader.h
//  IESGeckoKit
//
//  Created by liuhaitian on 2020/5/7.
//

#import "IESGurdProtocolDefines.h"

@interface IESGurdTTDownloader : NSObject <IESGurdDownloaderDelegate>

@property (class, nonatomic, assign, getter=isBackgroundDownloadEnabled) BOOL backgroundDownloadEnabled;

+ (void)setEnable:(BOOL)enable;

+ (void)handleBackgroundURLSessionWithIdentifier:(NSString *)identifier
                               completionHandler:(void (^)(void))completionHandler;

@end
