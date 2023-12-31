//
//  TTDispatchResult.mm
//  TTNetworkManager
//
//  Created by taoyiyuan on 2020/11/6.
//

#import "TTDispatchResult.h"
#import <Foundation/Foundation.h>

@implementation TTDispatchResult

- (id)initWithUrl:(NSString*)finalUrl etag:(NSString*)etag epoch:(NSString*)epoch  {
    self = [super init];
    if (self) {
        _finalUrl = finalUrl;
        _etag = etag;
        _epoch = epoch;
    }
    
    return self;
}

@end
