//
//  BDLynxResourceDownloader.h
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDLynxResourceDownloader : NSObject

+ (instancetype)sharedDownloader;

#if BDGurdLynxEnable
+ (void)loadBundle;
#endif

- (void)downloadLynxFile:(NSString *)sourceURL
              completion:(void (^)(NSError *error, NSString *location))completion;

@end

NS_ASSUME_NONNULL_END
