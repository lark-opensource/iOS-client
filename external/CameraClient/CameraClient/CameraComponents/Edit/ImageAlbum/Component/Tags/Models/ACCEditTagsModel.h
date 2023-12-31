//
//  ACCEditTagsModel.h
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/11.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCBaseApiModel.h>
#import <Mantle/Mantle.h>

typedef NS_ENUM(NSInteger, ACCTagsCommerceSearchType) {
    ACCTagsCommerceSearchTypeCommodity = 0,
    ACCTagsCommerceSearchTypeBrand = 1,
};

@interface ACCEditTagsURLModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong, readonly, nullable) NSArray *urlList;
@property (nonatomic, assign, readonly) CGFloat imageWidth;
@property (nonatomic, assign, readonly) CGFloat imageHeight;
@property (nonatomic, strong, readonly, nullable) NSString *URI;

@end

@interface ACCEditCommerceSearchResponse : ACCBaseApiModel

@property (nonatomic, strong, nullable) NSArray *commerceTags;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) NSInteger cursor;

@end

@interface ACCEditCommerceTagsModel :  MTLModel<MTLJSONSerializing>

@property (nonatomic, strong, nullable) ACCEditTagsURLModel *imageURL;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *itemID;
@property (nonatomic, copy, nullable) NSArray<NSString *> *categories;
@property (nonatomic, assign) ACCTagsCommerceSearchType type;
@property (nonatomic, assign) NSInteger importCount;
@property (nonatomic, copy, nullable) NSString *schema;

@end
