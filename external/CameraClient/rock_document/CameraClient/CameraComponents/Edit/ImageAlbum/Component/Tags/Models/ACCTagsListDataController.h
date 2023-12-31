//
//  ACCTagsListDataController.h
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/11.
//

#import <Foundation/Foundation.h>
#import "ACCEditTagsModel.h"

@interface ACCTagsListDataController : NSObject

@property (nonatomic, assign) ACCTagsCommerceSearchType type;

- (void)fetchRecommendDataWithCompletion:(void (^)(NSArray * _Nullable, NSString * _Nullable, BOOL))completion;

- (void)searchWithKeyword:(NSString * _Nullable)keyword completion:(void (^)(NSArray * _Nullable, NSString * _Nullable, BOOL))completion;

- (void)loadMoreWithKeyword:(NSString * _Nullable)keyword completion:(void (^)(NSArray * _Nullable, NSString * _Nullable, BOOL))completion;

@end
