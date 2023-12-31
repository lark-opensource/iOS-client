//
//  TTDispatchResult.h
//  TTNetworkManager
//
//  Created by taoyiyuan on 2020/11/6.
//

#import <Foundation/Foundation.h>

@interface TTDispatchResult : NSObject


// The final url by URL-Dispatch module from TTNet, may be nil.
@property(nonatomic, copy) NSString* finalUrl;

// The etag of TNC config, may be nil.
@property(nonatomic, copy) NSString* etag;

// The epoch of URL-Dispatch config, may be nil.
@property(nonatomic, copy) NSString* epoch;

- (id)initWithUrl:(NSString*)finalUrl etag:(NSString*)etag epoch:(NSString*)epoch;

@end
