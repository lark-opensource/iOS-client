//
//  AWEInteractionStickerModel.h
//  Pods
//
//  Created by chengfei xiao on 2019/12/9.
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AWETeenVideoVoteOptionType) {
    AWETeenVideoVoteOptionTypePositive = 1001,
    AWETeenVideoVoteOptionTypeNegative = 1002,
};

typedef NS_ENUM(NSInteger, ACCPollStickerViewStyle) {
    ACCPollStickerViewStyleEdit = 0, //The default is edit page style
    ACCPollStickerViewStyleUnPolled = 1, //Non voting style
    ACCPollStickerViewStylePolled = 2, //Voted style
    ACCPollStickerViewStyleResult = 3 //Voting result style
};

@interface AWEInteractionStickerLocationModel : MTLModel<MTLJSONSerializing, NSCopying>
@property (nonatomic, strong, nullable) NSDecimalNumber * x;
@property (nonatomic, strong, nullable) NSDecimalNumber * y;
@property (nonatomic, strong, nullable) NSDecimalNumber * width;
@property (nonatomic, strong, nullable) NSDecimalNumber * height;
@property (nonatomic, strong, nullable) NSDecimalNumber * rotation;
@property (nonatomic, strong, nullable) NSDecimalNumber * scale;
@property (nonatomic, strong, nullable) NSDecimalNumber * pts;
@property (nonatomic, strong, nullable) NSDecimalNumber * startTime; // ms
@property (nonatomic, strong, nullable) NSDecimalNumber * endTime; // ms
@property (nonatomic, assign) BOOL isRatioCoord;
- (void)reset;
+ (NSDecimalNumber *)convertCGFloatToNSDecimalNumber:(CGFloat)value;
@end

@interface AWEInteractionExtraModel : MTLModel<MTLJSONSerializing>
@property (nonatomic,   copy) NSString *stickerID;
@property (nonatomic, assign) NSInteger type;// Reserved, in the future 
@property (nonatomic,   copy) NSString *popIcon;
@property (nonatomic,   copy) NSString *popText;
@property (nonatomic,   copy) NSString *schemeURL;
@property (nonatomic,   copy) NSString *clickableOpenURL;
@property (nonatomic,   copy) NSString *clickableWebURL;
@end

@interface AWEInteractionVoteStickerOptionsModel : MTLModel<MTLJSONSerializing>
@property (nonatomic,   copy) NSString *optionText;
@property (nonatomic,   strong) NSNumber *optionID;
@property (nonatomic, assign) NSInteger voteCount;
@end

@interface AWEInteractionVoteStickerInfoModel : MTLModel<MTLJSONSerializing>
@property (nonatomic,   copy) NSString *question;
@property (nonatomic,   strong) NSNumber *voteID;
@property (nonatomic,   strong) NSNumber *refID;
@property (nonatomic, assign) NSInteger refType;
@property (nonatomic, strong) NSArray<AWEInteractionVoteStickerOptionsModel*> *options;
@property (nonatomic,   strong) NSNumber *selectOptionID;
@property (nonatomic, assign) ACCPollStickerViewStyle style;
@end

@interface AWEInteractionStickerModel : MTLModel<MTLJSONSerializing>

//common
// in order to sink files, type not have specific enum declaration, if add type value, please search for AWEInteractionStickerType
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy) NSString *stickerID;
@property (nonatomic, assign) NSInteger index;// hierarchical
@property (nonatomic, assign) NSInteger imageIndex;// image index in image mode
@property (nonatomic, assign) BOOL adaptorPlayer;// Whether it adapts Player
@property (nonatomic, copy, nullable) NSString *trackInfo;//NSArray<AWEInteractionStickerLocationModel *> json string //Location on the screen
@property (nonatomic, copy) NSString *attr; // General storage field used for extra sticker information (stored as a json string)
@property (nonatomic, assign) BOOL isAutoAdded;  /// It is a sticker that is automatically added to the editing page, generally used for a point

#pragma mark  - custom
@property (nonatomic,   copy) NSString *voteID;
@property (nonatomic, strong) AWEInteractionVoteStickerInfoModel *voteInfo;
@property (nonatomic, copy) NSString *textInfo;

@property (nonatomic, copy) NSString *localStickerUniqueId;

- (AWEInteractionStickerLocationModel *)fetchLocationModelFromTrackInfo;
- (BOOL)storeLocationModelToTrackInfo:(AWEInteractionStickerLocationModel *)locationModel;

@end

NS_ASSUME_NONNULL_END
