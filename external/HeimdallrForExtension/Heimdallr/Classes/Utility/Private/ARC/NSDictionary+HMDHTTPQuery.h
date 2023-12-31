//
//  NSDictionary+HMDHTTPQuery.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/12.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (HMDHTTPQuery)
- (NSString *)hmd_queryString;

- (id)hmd_objectForInsensitiveKey:(NSString *)key;
@end

