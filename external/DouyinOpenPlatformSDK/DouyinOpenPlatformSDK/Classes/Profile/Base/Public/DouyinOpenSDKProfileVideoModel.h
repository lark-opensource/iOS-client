//
//  DouyinOpenSDKProfileVideoModel.h
//  DouyinOpenPlatformSDK
//
//  Created by bytedance on 2022/2/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DouyinOpenSDKProfileVideoModel: NSObject

@property (nonatomic, assign) NSInteger collectCount;
@property (nonatomic, assign) NSInteger diggCount;
@property (nonatomic, assign) NSInteger commentCount;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, strong) NSURL* coverURL;
@property (nonatomic, strong, nullable) NSURL* videoURL; //to be filled by requestVideo
@property (nonatomic, strong) NSString* errMsg; //to be filled by requestVideo
@property (nonatomic, strong) NSString* musicTitle;
@property (nonatomic, assign) NSInteger localIndex;
@property (nonatomic, strong) NSString* awemeId;
@property (nonatomic, strong) NSString* desc;
@property (nonatomic, assign) NSInteger isTop;

@end

@interface DouyinOpenSDKCallBackVideoModel: NSObject

@property (nonatomic, assign) NSInteger collectCount; //收藏数
@property (nonatomic, assign) NSInteger commentCount; //评论数
@property (nonatomic, assign) NSInteger diggCount; // 点赞数
@property (nonatomic, strong) NSURL* coverURL;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger isTop;

@end

NS_ASSUME_NONNULL_END

