//
//  ACCDraftModelProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/14.
// Fill in the fields when sinking

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCDraftModelProtocol <NSObject>

@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *draftID;
@property (nonatomic,   copy) NSString *draftTrackID;
@property (nonatomic, strong) NSNumber *createTimestamp;
@property (nonatomic, strong) NSDate *saveDate;
@property (nonatomic, copy) NSString *templateModelId; // Selected topic template ID
@property (nonatomic, assign) BOOL backup;
@property (nonatomic, copy) NSString *zipURI;
@property (nonatomic, assign) double maxDuration;
@property (nonatomic, assign) NSInteger itemComment;
@property (nonatomic, assign) NSInteger itemDownload;

// Related hot spots
@property (nonatomic, copy) NSString *hotSpotWord;

@end

NS_ASSUME_NONNULL_END
