//
//  AWEEffectPlatformTrackModel.h
//  CameraClient
//
//  Created by Howie He on 2021/3/18.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@class IESEffectModel;
NS_ASSUME_NONNULL_BEGIN

/// For burying point
@interface AWEEffectPlatformTrackModel : MTLModel

@property (nonatomic, copy) NSString *trackName; ///< monitor name
@property (nonatomic, copy) NSNumber *successStatus; ///< success status
@property (nonatomic, copy) NSNumber *failStatus; ///< failure status
@property (nonatomic, copy, nullable) NSNumber *startTime; ///< start timing
@property (nonatomic, copy, nullable) NSString *effectIDKey; ///< key of the effect ID point
@property (nonatomic, copy, nullable) NSString *effectNameKey; ///< hit the key of effectname
@property (nonatomic, copy, nullable) NSDictionary *trackInfoDict; ///< buried point information
@property (nonatomic, copy, nullable) NSDictionary *(^extraTrackInfoDictBlock)(IESEffectModel *effect, NSError *error); ///< add buried point after download

/// Factory approach
+ (instancetype)modernStickerTrackModel; /// Props

@end

NS_ASSUME_NONNULL_END
