//
//  ACCMusicRecommendPropModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Lincoln on 2020/12/17.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMusicRecommendPropModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSNumber *statusCode;
@property (nonatomic, copy) NSString *errorMessage;
@property (nonatomic, copy) NSString *effectID;

@end

NS_ASSUME_NONNULL_END
