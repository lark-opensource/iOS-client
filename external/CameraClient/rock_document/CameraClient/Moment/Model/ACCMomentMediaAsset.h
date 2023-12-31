//
//  ACCMomentMediaAsset.h
//  Pods
//
//  Created by Pinka on 2020/5/19.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <CoreLocation/CLLocation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMomentMediaAsset : MTLModel

#pragma mark - Scan relate
@property (nonatomic, assign) NSUInteger scanDate;

@property (nonatomic, assign) BOOL didProcessed;

#pragma mark - PHAsset properties
@property (nonatomic, copy  ) NSString *localIdentifier;

@property (nonatomic, assign) PHAssetMediaType mediaType;
@property (nonatomic, assign) PHAssetMediaSubtype mediaSubtypes;

@property (nonatomic, assign) NSUInteger pixelWidth;
@property (nonatomic, assign) NSUInteger pixelHeight;

@property (nonatomic, strong, nullable) NSDate *creationDate;
@property (nonatomic, strong, nullable) NSDate *modificationDate;

@property (nonatomic, assign) NSTimeInterval duration;

- (instancetype)initWithPHAsset:(PHAsset *)asset;

@end

NS_ASSUME_NONNULL_END
