#ifndef IESForestDefines_h
#define IESForestDefines_h

@class IESForestResponse;
typedef void (^IESForestCompletionHandler)(IESForestResponse *__nullable response, NSError *__nullable error);

#pragma mark-- IESForestRequestOperation

@protocol IESForestRequestOperation <NSObject>

@property (nonatomic, copy) NSString * _Nullable url;

- (BOOL)cancel;

@end

#endif /* IESForestDefines_h */
