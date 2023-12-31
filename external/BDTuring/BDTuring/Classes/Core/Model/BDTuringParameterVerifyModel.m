//
//  BDTuringParameterVerifyModel.m
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringParameterVerifyModel.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyModel+View.h"
#import "BDTuringVerifyModel+Parameter.h"
#import "BDTuringUtility.h"
#import "BDTuringVerifyState.h"
#import "BDTuringCoreConstant.h"
#import "NSDictionary+BDTuring.h"
#import "NSObject+BDTuring.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringVerifyViewDefine.h"

#import "BDTuringPictureVerifyModel.h"
#import "BDTuringSlidePictureVerifyModel.h"
#import "BDTuringWhirlPictureVerifyModel.h"
#import "BDTuringAccessibilityModel.h"
#import "BDTuringSMSVerifyModel.h"
#import "BDTuringQAVerifyModel.h"

NSDictionary<NSString *,Class<BDTuringParameterModel>> *supportTypes = nil;

@interface BDTuringParameterVerifyModel ()

@property (nonatomic, copy) NSDictionary *verifyData;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *verifyScene;

@end

@implementation BDTuringParameterVerifyModel

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportTypes = @{
            @"sms" : [BDTuringSMSVerifyModel class],
            @"slide": [BDTuringSlidePictureVerifyModel class],
            @"3d": [BDTuringPictureVerifyModel class],
            @"qa": [BDTuringQAVerifyModel class],
            @"text": [BDTuringPictureVerifyModel class],
            @"whirl": [BDTuringWhirlPictureVerifyModel class],
            @"voice": [BDTuringAccessibilityModel class],
        };
    });
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self createState];
    }
    
    return self;
}

+ (BOOL)canHandleParameter:(NSDictionary *)parameter {
    if (!BDTuring_isValidDictionary(parameter)) {
        return NO;
    }
    NSString *subType = [parameter turing_stringValueForKey:@"subtype"].lowercaseString;
    if (!BDTuring_isValidString(subType)) {
        return NO;
    }
    
    NSString *code = [parameter turing_stringValueForKey:@"code"].lowercaseString;
    if (![code isEqualToString:@"10000"])  {
        return NO;
    }
    
    NSString *type = [parameter turing_stringValueForKey:kBDTuringType].lowercaseString;
    if (![type isEqualToString:@"verify"])  {
        return NO;
    }
    if ([supportTypes objectForKey:subType] == nil) {
        return NO;
    }
        
    return YES;
}

+ (instancetype)modelWithParameter:(NSDictionary *)parameter {
    BDTuringParameterVerifyModel *result = [super modelWithParameter:parameter];
    
    NSString *type = [parameter turing_stringValueForKey:kBDTuringType].lowercaseString;
    NSString *subtype = [parameter turing_stringValueForKey:@"subtype"].lowercaseString;
    NSString *region = [parameter turing_stringValueForKey:kBDTuringRegion];
    
    result.state.subType = subtype;
    result.region = region;
    result.type = type;
    result.verifyData = [parameter turing_safeJsonObject];
    result.verifyScene = [parameter turing_stringValueForKey:@"verify_scene"];
    Class<BDTuringParameterModel> clazz = [supportTypes objectForKey:subtype];
    result.actualModel = [clazz modelWithParameter:result.verifyData];
    
    return result;
}

- (NSString *)handlerName {
    return self.actualModel.handlerName;
}

- (NSString *)plugin {
    return self.actualModel.plugin;
}

- (BOOL)supportLandscape {
    return self.actualModel.supportLandscape;
}

/// override it
- (void)setRegionType:(BDTuringRegionType)regionType {
}

- (void)setAppID:(NSString *)appID {
    [super setAppID:appID];
    self.actualModel.appID = appID;
}

- (NSString *)appID {
    return self.actualModel.appID;
}

- (void)appendCommonKVParameters:(NSMutableDictionary *)paramters {
    [super appendCommonKVParameters:paramters];
    [self.actualModel appendCommonKVParameters:paramters];
}

- (void)appendKVToQueryParameters:(NSMutableDictionary *)paramters {
    [super appendKVToQueryParameters:paramters];
    [self.actualModel appendKVToQueryParameters:paramters];
    [paramters setValue:[self.verifyData turing_JSONRepresentationForJS] forKey:@"verify_data"];
}

- (void)appendKVToEventParameters:(NSMutableDictionary *)paramters {
    [super appendKVToQueryParameters:paramters];
    [self.actualModel appendKVToEventParameters:paramters];
    [paramters setValue:self.state.subType forKey:kBDTuringMode];
    [paramters setValue:self.verifyScene forKey:@"verify_scene"];
}

- (BDTuringVerifyView *)createVerifyView {
    return [self.actualModel createVerifyView];
}

- (void)configVerifyView:(BDTuringVerifyView *)verifyView {
    [super configVerifyView:verifyView];
    [self.actualModel configVerifyView:verifyView];
}

@end
