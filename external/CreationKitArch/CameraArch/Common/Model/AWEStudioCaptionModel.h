//
//  AWEStudioCaptionModel.h
//  Pods
//
//  Created by lixingdong on 2019/8/29.
//

#import <CreationKitInfra/ACCBaseApiModel.h>
#import <CreationKitArch/AWEStoryTextImageModel.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>

@class AWEStudioCaptionModel, AWEStudioCaptionQueryModel, AWEInteractionStickerLocationModel;

@interface AWEStudioCaptionCommitModel : ACCBaseApiModel

@property (nonatomic, strong) AWEStudioCaptionQueryModel *videoCaption;

@end

@interface AWEStudioCaptionQueryModel : ACCBaseApiModel

@property (nonatomic, strong) NSString *captionId;
@property (nonatomic, assign) NSInteger code;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, copy) NSArray<AWEStudioCaptionModel *> *captions;

@end

@interface AWEStudioCaptionInfoModel : ACCBaseApiModel<MTLJSONSerializing, NSCopying>

@property (nonatomic, copy) NSArray<AWEStudioCaptionModel *> *captions;
@property (nonatomic, strong) AWEStoryTextImageModel *textInfoModel;
@property (nonatomic, strong) AWEInteractionStickerLocationModel *location;

- (NSString *)md5;

@end


typedef BOOL(^AWEStudioCaptionModelShouldInvokeSelectedRangeBlock)(void);
@interface AWEStudioCaptionModel : ACCBaseApiModel<MTLJSONSerializing, NSCopying>

@property (nonatomic, strong) NSString *text;                           // Text information
@property (nonatomic, assign) CGFloat startTime;                        // Start time
@property (nonatomic, assign) CGFloat endTime;                          // End time
@property (nonatomic, copy) NSArray<AWEStudioCaptionModel *> *words;    // Word granularity information
@property (nonatomic, copy) NSArray<NSValue *> *lineRectArray;          // Width and height information of each line of current subtitle
@property (nonatomic, strong) NSString *rect;                           // Width and height information of current subtitle textview

// not mapping properties
@property (nonatomic, assign) NSRange selectedRange;
@property (nonatomic, copy) dispatch_block_t selectedRangeBlock;
@property (nonatomic, assign) BOOL isBuildingCell;
@property (nonatomic, copy) AWEStudioCaptionModelShouldInvokeSelectedRangeBlock shouldInvokeSelectedBlock;

@end
