//
//  IESCompositionInfoModel.h
//  IESVideoDebug
//
//  Created by geekxing on 2020/6/2.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <Mantle/Mantle.h>

@interface IESCompositionTrackSegmentInfo : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) CMTimeRange timeRange;
@property (nonatomic, assign) BOOL        empty;
@property (nonatomic, copy) NSString    *mediaType;
@property (nonatomic, copy) NSString    *descr;

@end


@interface IESVideoCompositionStageInfo : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) CMTimeRange     timeRange;
@property (nonatomic, copy)   NSArray<NSString *> *layerNames; // for videoComposition onlyerN
@property (nonatomic, copy)   NSDictionary *opacityRamps; // {name: [pt1,pt2], ...}

@end

@interface IESCompositionInfoModel : MTLModel<MTLJSONSerializing>

// array<array<IESCompositionTrackSegmentInfo >>
@property (nonatomic, copy) NSArray *compositionTracks;
@property (nonatomic, copy) NSArray *audioMixTracks; // [[pt1,pt2], ...]
@property (nonatomic, copy) NSArray<IESVideoCompositionStageInfo *> *videoCompositionStages;
@property (nonatomic, assign) CMTime duration;
    
- (void)synchronizeToComposition:(AVAsset *)composition videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix;

@end
