//
//  ACCTextReadingRequestHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/7/27.
//

#import <Foundation/Foundation.h>

//Just For TextReading , it needs poll request
@interface ACCTextReadingRequestHelper : NSObject

+ (ACCTextReadingRequestHelper *)sharedHelper;

- (void)requestTextReadingForUploadText:(NSString *)uploadText
                               filePath:(NSString *)filePath
                        completionBlock:(void(^)(BOOL, NSString *, NSError *))completionBlock;

- (void)requestTextReaderForUploadText:(NSString *)uploadText
                           textSpeaker:(NSString *)textSpeaker
                              filePath:(NSString *)filePath
                       completionBlock:(void(^)(BOOL, NSString *, NSError *))completionBlock;

- (void)cancelTextReadingRequest;

@end
