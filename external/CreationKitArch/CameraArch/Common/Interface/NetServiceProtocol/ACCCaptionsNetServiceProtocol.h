//
//  ACCCaptionsNetServiceProtocol.h
//  CameraClient
//
//  Created by wishes on 2019/12/9.
//

#ifndef ACCCaptionsNetServiceProtocol_h
#define ACCCaptionsNetServiceProtocol_h

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEStudioCaptionModel.h>

typedef void (^ACCCaptionsNetCompletionBlock)(AWEStudioCaptionCommitModel* _Nullable model, NSError * _Nullable error);


NS_ASSUME_NONNULL_BEGIN

@protocol ACCCaptionsNetServiceProtocol <NSObject>

/*
*  Search for subtitles
*/
- (void)queryCaptionWithTaskId:(NSString *)taskId
                    completion:(ACCCaptionsNetCompletionBlock)completion;

/*
*  Submit subtitles
*/
- (void)commitAudioWithMaterialId:(NSString *)materialId
                         maxLines:(NSNumber *)maxLine
                     wordsPerLine:(NSNumber *)wordsPerLine
                       completion:(ACCCaptionsNetCompletionBlock)completion;

/*
*  Feedback caption information
*/
- (void)feedbackCaptionWithAwemeId:(nonnull NSString *)awemeId
                            taskID:(NSString *)taskId
                               vid:(NSString *)vid
                        utterances:(NSArray *)captionsArr;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCCaptionsNetServiceProtocol_h */
