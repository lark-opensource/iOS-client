//
//  DouyinOpenSDKShareRequest+Privates.h
//  AFgzipRequestSerializer
//
//  Created by Spiker on 2019/7/8.
//

#import "DouyinOpenSDKShare.h"

NS_ASSUME_NONNULL_BEGIN

@interface DouyinOpenSDKShareRequest ()

@property (nonatomic, readonly) NSDictionary *postExtraInfo;
@property (nonatomic, readonly) NSArray<NSString *> *schemaListForRequest;
@property (nonatomic, readonly) BOOL isVaild;

@end

NS_ASSUME_NONNULL_END
