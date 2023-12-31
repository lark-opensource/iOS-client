//
//  BDPSharePluginModel.h
//  Timor
//
//  Created by MacPu on 2019/1/2.
//

#import <OPFoundation/BDPBaseJSONModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDPShareAppType) {
    BDPShareAppTypeUnknow = 0,
    BDPShareAppTypeApp
};

@interface BDPSharePluginModel : BDPBaseJSONModel

@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, copy) NSString *miniImageUrl;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *ugUrl;
@property (nonatomic, copy) NSString *query;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *appIcon;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *schema;
@property (nonatomic, assign) BOOL withShareTicket;
@property (nonatomic, assign) BDPShareAppType appType;
@property (nonatomic, strong) NSDictionary *extra;
@property (nonatomic, copy) NSString *desc;

@end

NS_ASSUME_NONNULL_END
