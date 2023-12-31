//
//  IESLiveResouceBundle+PageUrl.h
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceBundle.h"

typedef NSString * (^IESLiveResoucePageUrl)(NSString *key, NSDictionary *params);

@interface IESLiveResouceBundle (PageUrl)

- (IESLiveResoucePageUrl)page;
- (IESLiveResoucePageUrl)pageNoQuery;

@end
