//
//  JSValue+BDPExtension.h
//  Timor
//
//  Created by MacPu on 2019/6/11.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JSValue (BDPExtension)

- (NSDictionary *)bdp_object;

- (NSDictionary *)bdp_convert2Object;

@end

NS_ASSUME_NONNULL_END
