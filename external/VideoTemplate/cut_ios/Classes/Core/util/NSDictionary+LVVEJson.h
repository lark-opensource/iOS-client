//
//  NSDictionary+LVVEJson.h
//  VideoTemplate
//
//  Created by ZhangYuanming on 2020/1/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (LVVEJson)
- (NSString *)lvve_jsonString;
@end

@interface NSString (LVVEJson)
- (NSDictionary *)lvve_json;
@end

NS_ASSUME_NONNULL_END
