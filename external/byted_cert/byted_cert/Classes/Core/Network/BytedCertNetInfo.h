//
//  BytedCertNetInfo.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertNetInfo : NSObject

@property (nonatomic, copy, nonnull) NSString *url;
@property (nonatomic, copy, nonnull) NSString *method;
@property (nonatomic, copy, nullable) NSArray *binaryDatas;
@property (nonatomic, copy, nullable) NSArray *binaryNames;
@property (nonatomic, copy, nullable) NSString *filePath;
@property (nonatomic, copy, nonnull) NSDictionary *params;
@property (nonatomic, copy, nullable) NSDictionary *headerField;

@end

NS_ASSUME_NONNULL_END
