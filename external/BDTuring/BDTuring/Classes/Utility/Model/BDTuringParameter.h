//
//  BDTuringParameter.h
//  BDTuring
//
//  Created by bob on 2020/9/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDTuringVerifyModel;

@protocol BDTuringVerifyModelCreator <NSObject>

+ (BOOL)canHandleParameter:(NSDictionary *)parameter;
+ (__kindof BDTuringVerifyModel *)modelWithParameter:(NSDictionary *)parameter;

@end

@interface BDTuringParameter : NSObject

/// shared app id for network handling
@property (nonatomic, copy, nullable) NSString *appID;

+ (instancetype)sharedInstance;

- (void)updateCurrentParameter:(NSDictionary *)parameter;
- (nullable NSDictionary *)currentParameter;

- (void)addCreator:(Class<BDTuringVerifyModelCreator>)creator;
- (nullable BDTuringVerifyModel *)modelWithParameter:(NSDictionary *)parameter;

@end

NS_ASSUME_NONNULL_END
