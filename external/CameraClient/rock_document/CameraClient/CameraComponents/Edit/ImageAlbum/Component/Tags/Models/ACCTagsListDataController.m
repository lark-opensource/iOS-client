//
//  ACCTagsListDataController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/11.
//

#import "ACCTagsListDataController.h"
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCMainServiceProtocol.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>

@interface ACCTagsListDataController ()
@property (nonatomic, assign) NSInteger currentCursor;
@end

@implementation ACCTagsListDataController

- (void)fetchRecommendDataWithCompletion:(void (^)(NSArray *, NSString *, BOOL))completion
{
    NSDictionary *params = [self requestParametersWithKeyword:@"" requestType:@"recommend"];
    NSString *url = [self requestURL];
    @weakify(self)
    [ACCNetService() GET:url
                  params:params
              modelClass:[ACCEditCommerceSearchResponse class]
              completion:^(ACCEditCommerceSearchResponse *  _Nullable model, NSError * _Nullable error) {
        @strongify(self)
        self.currentCursor = model.cursor;
        ACCBLOCK_INVOKE(completion, model.commerceTags, @"", model.hasMore);
    }];
}

- (void)searchWithKeyword:(NSString *)keyword completion:(void (^)(NSArray *, NSString *, BOOL))completion
{
    NSString *requestType = ACC_isEmptyString(keyword) ? @"recommend" : @"search";
    NSDictionary *params = [self requestParametersWithKeyword:keyword requestType:requestType];
    NSString *url = [self requestURL];
    @weakify(self)
    [ACCNetService() GET:url
                  params:params
              modelClass:[ACCEditCommerceSearchResponse class]
              completion:^(ACCEditCommerceSearchResponse *  _Nullable model, NSError * _Nullable error) {
        @strongify(self)
        self.currentCursor = model.cursor;
        ACCBLOCK_INVOKE(completion, model.commerceTags, keyword, model.hasMore);
    }];
}

- (void)loadMoreWithKeyword:(NSString *)keyword completion:(void (^)(NSArray *, NSString *, BOOL))completion
{
    NSDictionary *params = [self requestParametersWithKeyword:keyword requestType:@"search"];
    NSString *url = [self requestURL];
    @weakify(self)
    [ACCNetService() GET:url
                  params:params
              modelClass:[ACCEditCommerceSearchResponse class]
              completion:^(ACCEditCommerceSearchResponse *  _Nullable model, NSError * _Nullable error) {
        @strongify(self)
        self.currentCursor = model.cursor;
        ACCBLOCK_INVOKE(completion, model.commerceTags, keyword, model.hasMore);
    }];
}

- (NSDictionary *)requestParametersWithKeyword:(NSString *)keyword requestType:(NSString *)requestType
{
    return @{
        @"query_word" : keyword ? : @"",
        @"cursor" : @(self.currentCursor),
        @"count" : @(20),
        @"recommend_strategy" : requestType ? : @"",
        @"need_personal_recommend" : @([IESAutoInline(ACCBaseServiceProvider(), ACCMainServiceProtocol) isPersonalRecommendSwitchOn]),
        @"teen_mode" : @([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isChildMode]),
        @"update_version_code" : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ? : @"",
    };
}

- (NSString *)requestURL
{
    NSString *requestPath = @"/ecom/video/tag_list/product";
    return [NSString stringWithFormat:@"%@%@", @"https://ecom.snssdk.com", requestPath];
}

@end
