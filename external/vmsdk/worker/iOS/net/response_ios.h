#import <Foundation/Foundation.h>

@class JsWorkerIOS;

@interface ResponseIOS : NSObject

@property(readonly) NSInteger statusCode;
@property(nullable, readonly, copy) NSURL *url;
@property(nullable, readonly, copy) NSString *MIMEType;
@property(nullable, readonly, copy) NSDictionary *headers;
@property bool ok;
- (instancetype _Nonnull)init:(NSInteger)statusCode
                          url:(NSString *_Nonnull)url
                     mimeType:(NSString *_Nonnull)mimeType
                      headers:(NSDictionary *_Nonnull)headers;
- (void)Resolve:(JsWorkerIOS *_Nonnull)worker
           body:(NSData *_Nonnull)body
         delPtr:(void *_Nonnull)delPtr;
- (void)Reject:(JsWorkerIOS *_Nonnull)worker
         error:(NSError *_Nonnull)error
        delPtr:(void *_Nonnull)delPtr;
@end
