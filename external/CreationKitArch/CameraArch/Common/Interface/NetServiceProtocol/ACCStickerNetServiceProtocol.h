//
//  ACCStickerNetServiceProtocol.h
//  CameraClient
//
//  Created by wishes on 2019/12/9.
//

#ifndef ACCStickerNetServiceProtocol_h
#define ACCStickerNetServiceProtocol_h

#import <Foundation/Foundation.h>
#import "ACCStudioNewFaceStickerModelProtocol.h"
#import "AWEInfoStickerResponse.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerNetServiceProtocol <NSObject>

/*
* Get sticker details
* @param stickerIds sticker id
*/
- (void)requestStickerWithId:(NSString *)stickerId
                  completion:(void (^)(id<ACCStudioNewFaceStickerModelProtocol> _Nullable firstStickerModel, NSError * _Nullable error))completion;

@end

@protocol ACCTextStickerNetServiceProtocol <NSObject>

/*
* Get the rotation token corresponding to the text-to-speech
* @param uploadText Input text
* @return request object
*/
- (id)requestPollTokenForTextReading:(NSString *)uploadText completionBlock:(void(^)(BOOL, NSString *, NSError *))completionBlock;

/*
* Get voice resources based on token
* @param token token
* @return request object
*/
- (id)pollAudioForTextReadingToken:(NSString *)token completionBlock:(void(^)(BOOL, NSData *, NSError *error))completionBlock;

@end

@protocol ACCTextStickerReadingNetServiceProtocol <NSObject>
@optional
/*
*  get TTS audio, sync
*  @param uploadText input text
*  @param textSpeaker sound effect's name
*  @return tts audio
*/
- (id)requestAudioForTextReading:(NSString *)uploadText
                     textSpeaker:(NSString *)textSpeaker
                 completionBlock:(void (^)(NSError *, BOOL, NSData *))completionBlock;

- (id)requestAudioForTextReading:(NSString *)uploadText
                      completion:(void(^)(BOOL, NSData *, NSError *))completion;

@end

@protocol ACCTextLibararyNetServiceProtocol <NSObject>

- (id)requestTextRecommendForZipURI:(NSString *)zipURI
                         creationId:(NSString *)creationId
                            keyword:(NSString *)keyword
                    completionBlock:(void (^)(NSError *, NSArray *))completionBlock;

- (id)requestTextLibForZipURI:(NSString *)zipURI
                   creationId:(NSString *)creationId
              completionBlock:(void (^)(NSError *, NSArray *))completionBlock;

@end

@protocol ACCCountDownStickerNetServiceProtocol <NSObject>

- (id)requestCountDownPermission:(void(^)(BOOL, NSError *))completion;

@end


NS_ASSUME_NONNULL_END

#endif /* ACCStickerNetServiceProtocol_h */
