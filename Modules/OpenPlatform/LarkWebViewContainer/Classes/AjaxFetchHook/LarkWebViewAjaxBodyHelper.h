#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LarkWebViewAjaxBodyHelper : NSObject

+ (void)setBodyRequest:(NSDictionary *)bodyRequest toRequest:(NSMutableURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
