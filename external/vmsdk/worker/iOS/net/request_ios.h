#import <Foundation/Foundation.h>

@interface RequestIOS : NSObject

@property(nonnull, copy) NSURL* url;
@property(nonnull, copy) NSString* method;
@property(nullable, copy) NSData* body;
@property(nullable, copy) NSDictionary<NSString*, NSString*>* headers;

- (instancetype _Nonnull)init:(NSString* _Nonnull)url;

- (instancetype _Nonnull)init:(NSString* _Nonnull)url method:(NSString* _Nonnull)method;

- (instancetype _Nonnull)init:(NSString* _Nonnull)url
                       method:(NSString* _Nonnull)method
                      headers:(NSDictionary* _Nullable)headers;

- (instancetype _Nonnull)init:(NSString* _Nonnull)url
                       method:(NSString* _Nonnull)method
                      headers:(NSDictionary* _Nullable)headers
                         body:(NSData* _Nullable)body;
@end
