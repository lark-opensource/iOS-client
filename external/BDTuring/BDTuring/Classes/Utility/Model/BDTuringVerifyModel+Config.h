//
//  BDTuringVerifyModel+Config.h
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringVerifyModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringVerifyState;

@interface BDTuringVerifyModel (Config)

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, assign) BDTuringVerifyType verifyType;
@property (nonatomic, copy) NSString *plugin;
@property (nonatomic, copy) NSString *region;
@property (nonatomic, assign) NSInteger showToast;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, strong) BDTuringVerifyState *state;
@property (nonatomic, copy) NSString *handlerName;
@property (nonatomic, assign) BOOL supportLandscape;

- (void)createState;

- (void)appendCommonKVParameters:(NSMutableDictionary *)paramters;
- (void)appendKVToQueryParameters:(NSMutableDictionary *)paramters;
- (void)appendKVToEventParameters:(NSMutableDictionary *)paramters;

@end

NS_ASSUME_NONNULL_END
