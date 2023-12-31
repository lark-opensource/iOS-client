#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LarkWebViewFormDataFile : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, assign) NSUInteger lastModified;
@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSData *data;

@end

NS_ASSUME_NONNULL_END
