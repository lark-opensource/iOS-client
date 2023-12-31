//
//  BDPRedirectPageConfig.h
//  TTMicroApp
//
//  Created by yi on 2022/5/12.
//

#import <JSONModel/JSONModel.h>
@class BDPAppConfig;
@interface BDPRedirectPageConfig : JSONModel
@property (nonatomic, copy) NSString *fromPath;
@property (nonatomic, copy) NSString *toPath;
@end
