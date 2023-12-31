//
//  AWERepoPropModel.h
//  CameraClient
//
//  Created by haoyipeng on 2020/10/25.
//

#import <CreationKitArch/ACCRepoPropModel.h>

@class ACCStickerMultiSegPropClipModel;

NS_ASSUME_NONNULL_BEGIN

@interface AWERepoPropModel : ACCRepoPropModel

// local prop id
@property (nonatomic, copy) NSString *localPropId;

@property (nonatomic, copy) NSString *propId;

@property (nonatomic, copy) NSArray<NSString *> *propBindMusicIDArray;

@property (nonatomic, copy, nullable) NSArray <ACCStickerMultiSegPropClipModel *> * multiSegPropClipsArray;

// live duet posture images folder path
@property (nonatomic, copy) NSString *liveDuetPostureImagesFolderPath;
@property (nonatomic, assign) NSInteger selectedLiveDuetImageIndex;

- (BOOL)isMultiSegPropApplied; // multiSegPropClipsArray count > 0

@end

@interface AWEVideoPublishViewModel (AWERepoProp)
 
@property (nonatomic, strong, readonly) AWERepoPropModel *repoProp;
 
@end

NS_ASSUME_NONNULL_END
