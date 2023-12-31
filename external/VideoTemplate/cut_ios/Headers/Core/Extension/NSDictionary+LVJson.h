//
//  NSDictionary+LVJson.h
//  LVTemplate
//
//  Created by iRo on 2019/12/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (LVJson)
- (NSString *)lv_jsonString;
@end

@interface NSString (LVJson)
- (NSDictionary *)lv_json;
@end

NS_ASSUME_NONNULL_END
