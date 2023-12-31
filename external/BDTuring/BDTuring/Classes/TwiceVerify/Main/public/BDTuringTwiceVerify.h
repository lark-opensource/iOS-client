//
//  BDTuringTwiceVerify.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/11/2.
//

#import <Foundation/Foundation.h>
#import "BDTuringTVDefine.h"
#import "BDTuringDefine.h"


NS_ASSUME_NONNULL_BEGIN
@class BDTuringTwiceVerifyModel, BDTuringConfig;

@interface BDTuringTwiceVerify : NSObject <BDTuringVerifyHandler>

@property (nonatomic, strong) BDTuringConfig *config;

@property (nonatomic, strong) NSString *url;

+ (instancetype)twiceVerifyWithAppID:(NSString *)appid;

+ (instancetype)twiceVerifyWithConfig:(BDTuringConfig *)config;

- (instancetype)initWithConfig:(BDTuringConfig *)config;


- (void)popVerifyViewWithModel:(BDTuringVerifyModel *)model;

- (void)popVerifyViewWithModel:(BDTuringTwiceVerifyModel *)model callback:(BDTuringTVResponseCallBack)callback;

@end

NS_ASSUME_NONNULL_END
