//
//  BDWebURLSchemeTaskProxy.h
//  BDWebKit
//
//  Created by li keliang on 2020/4/3.
//

#import <Foundation/Foundation.h>
#import "BDWebURLSchemeTask.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(11.0))
@interface BDWebURLSchemeTaskProxy : NSObject<BDWebURLSchemeTaskDelegate>

@property (nonatomic, weak) id <WKURLSchemeTask> target;

@end

NS_ASSUME_NONNULL_END
