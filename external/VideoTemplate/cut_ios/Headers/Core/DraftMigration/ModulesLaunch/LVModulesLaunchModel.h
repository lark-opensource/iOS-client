//
//  LVModulesLaunchModel.h
//  Pods
//
//  Created by kevin gao on 11/3/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//启动项
@interface LVModulesLaunchItem : NSObject

@property (nonatomic, copy) NSString* key;

@property (nonatomic, assign) NSTimeInterval start;
@property (nonatomic, assign) NSTimeInterval end;
@property (nonatomic, assign) NSTimeInterval cost;

@property (nonatomic, copy) NSString* start_time;
@property (nonatomic, copy) NSString* end_time;

- (NSDictionary*)modelToJson;

@end

//草稿启动项统计
@interface LVModulesLaunchDraft : NSObject

@property (nonatomic, copy) NSString *draftID;

@property (nonatomic, copy) NSString* create_time;

@property (nonatomic, strong) NSMutableArray <LVModulesLaunchItem*> *items;

- (NSDictionary*)modelToJson;

@end

NS_ASSUME_NONNULL_END
