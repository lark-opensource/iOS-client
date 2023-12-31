//
//  BDAExtraVideoInfoModel.h
//  BDAlogProtocol
//
//  Created by YangFani on 2020/4/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAExtraVideoInfoModel : NSObject

@property (nonatomic, copy) NSString            * videoId;
@property (nonatomic, copy) NSString            * videoGroupId;
@property (nonatomic, copy) NSArray<NSString *> * videoURLArray;
@property (nonatomic, copy) NSArray<NSString *> * videoPlayTrackURLArray;
@property (nonatomic, copy) NSArray<NSString *> * videoPlayOverTrackURLArray;
@property (nonatomic, copy) NSString            * videoDensity;
@property (nonatomic, assign) CGFloat             videoDuration;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
