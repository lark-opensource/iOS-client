//
//  ACCRouterProtocolD.h
//  Indexer
//
//  Created by xiafeiyu on 11/19/21.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCRouterProtocol.h>

@protocol ACCRouterProtocolD <ACCRouterProtocol>

- (nullable NSString *)URLString:(nullable NSString *)URLString byAddingQueryDict:(NSDictionary *)queryDict;

@end
