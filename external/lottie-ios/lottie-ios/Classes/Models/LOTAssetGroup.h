//
//  LOTAssetGroup.h
//  Pods
//
//  Created by Brandon Withrow on 2/17/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class LOTAsset;
@class LOTLayerGroup;
@class LOTAnimationView;

@interface LOTAssetGroup : NSObject

@property (nonatomic, readwrite) NSString * _Nullable rootDirectory;
@property (nonatomic, readonly, nullable) NSBundle *assetBundle;
@property (nonatomic, strong, nullable) NSURL *baseURL;
@property (nonatomic, assign) BOOL ignoreBundleResource;
@property (nonatomic, weak) LOTAnimationView *referencedAnimationView;

- (instancetype _Nonnull)initWithJSON:(NSArray * _Nonnull)jsonArray
                      withAssetBundle:(NSBundle *_Nullable)bundle
                        withFramerate:(NSNumber * _Nonnull)framerate;

- (void)buildAssetNamed:(NSString * _Nonnull)refID withFramerate:(NSNumber * _Nonnull)framerate;

- (void)finalizeInitializationWithFramerate:(NSNumber * _Nonnull)framerate;

- (LOTAsset * _Nullable)assetModelForID:(NSString * _Nonnull)assetID;

@end
