//
//  TTTopSignature.h
//  TTTopSignature
//
//  Created by 黄清 on 2018/10/17.


#import <Foundation/Foundation.h>
#import "NSString+TSASignature.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTTopSignature : NSObject

@property(nonatomic,   copy) NSString* secretKey;
@property(nonatomic,   copy) NSString* accessKey;
@property(nonatomic,   copy) NSString* regionName;
@property(nonatomic,   copy) NSString* serviceName;
@property(nonatomic, assign) TSAHTTPMethod httpMethod;
@property(nonatomic,   copy) NSString* canonicalURI;
@property(nonatomic, strong) NSDictionary<NSString*,NSString*>* requestParameters;
@property(nonatomic, copy) NSDictionary<NSString*,NSArray<NSString*>*>* requestParametersArrary;

@property(nonatomic, strong) NSDictionary<NSString*,NSString*>* requestHeaders;
@property(nonatomic,   copy) NSString* payload;

/**
 get Signature data
 */
- (NSDictionary<NSString*,NSString*>*) signerHeaders;

@end

NS_ASSUME_NONNULL_END
