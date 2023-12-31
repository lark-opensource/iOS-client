//
//  ACCVideoPreloadProtocol.h
//  CameraClient
//
//  Created by long.chen on 2020/3/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCVideoPreloadProtocol <NSObject>

- (void)preloadVideo:(NSString *)videoID
         andVideoURL:(NSString *)urlString
               group:(NSString *)group
              fileCs:(NSString *)fileCs
              urlKey:(NSString *)urlKey;

- (void)cancelGroup:(NSString *)group;

@end

NS_ASSUME_NONNULL_END
