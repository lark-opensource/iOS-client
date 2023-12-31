//
//  ACCFilterDefine.h
//  CameraClient
//
//  Created by 郝一鹏 on 2020/1/13.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCFilterModel : MTLModel

@property (nonatomic, copy) NSString *filterID;
@property (nonatomic, copy) NSString *filterName;
@property (nonatomic, copy) NSString *path;

@property (nonatomic, strong) id originData;

@end

typedef NS_ENUM(NSUInteger, ACCFilterPanelType) {
    ACCFilterPanelTypeDefault = 0,
    ACCFilterPanelTypeSpecial = 1,
};

NS_ASSUME_NONNULL_END
