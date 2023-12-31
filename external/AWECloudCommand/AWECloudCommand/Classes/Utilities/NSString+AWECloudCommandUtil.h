//
//  NSString+AWECloudCommandUtil.h
//  AWECloudCommand
//
//  Created by wangdi on 2018/4/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (AWECloudCommandUtil)

- (NSString *)awe_urlStringByAddingComponentString:(NSString *)componentString;
- (NSString *)awe_urlStringByAddingComponentArray:(NSArray<NSString *> *)componentArray;
+ (NSString *)awe_queryStringWithParamDictionary:(NSDictionary *)param;

- (NSString *)cloudcommand_base64Decode;

@end

NS_ASSUME_NONNULL_END

