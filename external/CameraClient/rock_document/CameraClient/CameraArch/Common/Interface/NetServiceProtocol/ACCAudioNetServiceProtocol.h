//
//  ACCAudioServiceProtocol.h
//  CameraClient
//
//  Created by wishes on 2019/12/9.
//

#ifndef ACCAudioServiceProtocol_h
#define ACCAudioServiceProtocol_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ACCNetServiceCompletionBlock)(id _Nullable model, NSError * _Nullable error);

@protocol ACCAudioNetServiceProtocol <NSObject>

/*
*  更新音频
*  @param uri 上传成功的音频remote url
*/
- (void)updateAudioTrackWithId:(nonnull NSString*)cid
                 audiotrackUri:(nullable NSString*)uri
                    completion:(nullable ACCNetServiceCompletionBlock)completion;

- (void)updateAudioTrackWithId:(nonnull NSString*)cid
                 audiotrackUri:(nullable NSString*)uri
                        params:(NSDictionary *)params
                    completion:(nullable ACCNetServiceCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCAudioServiceProtocol_h */
