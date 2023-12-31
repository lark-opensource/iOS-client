//
//  KAServiceLocator.h
//  KAServiceLocator
//
//  Created by bytedance on 2021/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKServiceLocator : NSObject

+ (_Nullable id)locateService: (Protocol *)serviceProtocol;

@end

NS_ASSUME_NONNULL_END
