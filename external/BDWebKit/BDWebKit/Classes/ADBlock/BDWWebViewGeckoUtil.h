#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDWWebViewGeckoUtil : NSObject

+ (void)updateGeckoAccessKey:(NSString *_Nonnull)geckoAccessKey;

+ (NSString *)geckoAccessKey;

+ (BOOL)hasCacheForPath:(NSString *)path channel:(NSString *)channel;

+ (NSData *)geckoDataForPath:(NSString *)path channel:(NSString *)channel;

+ (nullable NSString *)geckoVersionForChannel:(NSString *)channel;

@end

NS_ASSUME_NONNULL_END
