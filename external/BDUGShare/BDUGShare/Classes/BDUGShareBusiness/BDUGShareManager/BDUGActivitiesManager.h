//
//  TTActivitiesManager.h
//  BDUGActivityViewControllerDemo
//
//  Created by 延晋 张 on 16/6/1.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"

#import "BDUGShareActivityDataModel.h"

@interface BDUGActivitiesManager : NSObject

+ (instancetype)sharedInstance;

- (void)addValidActivitiesFromArray:(NSArray *)activities;

- (void)addValidActivity:(id <BDUGActivityProtocol>)activity;

- (NSArray *)validActivitiesForContent:(NSArray *)contentArray hiddenContentArray:(NSArray *)hiddenContentArray panelId:(NSString *)panelId;

- (id <BDUGActivityProtocol>)getActivityByItem:(id <BDUGActivityContentItemProtocol>)item panelId:(NSString *)panelId;

@end
