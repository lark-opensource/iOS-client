//
//  ACCMVCategoryModel.h
//  CameraClient
//
//  Created by long.chen on 2020/3/12.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

#import <CreationKitInfra/ACCBaseApiModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCMVCategoryType) {
    ACCMVCategoryTypeClassic = 0,
    ACCMVCategoryTypeCutTheSame,
    
    ACCMVCategoryTypeFavorite = 999,
};

@interface ACCMVCategoryModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSInteger categoryID;
@property (nonatomic, copy) NSString *categoryName;
@property (nonatomic, assign) ACCMVCategoryType categoryType;

@end


@interface ACCMVCategoryReponseModel : ACCBaseApiModel

@property (nonatomic, copy) NSArray<ACCMVCategoryModel *> *categories;

@end

NS_ASSUME_NONNULL_END
