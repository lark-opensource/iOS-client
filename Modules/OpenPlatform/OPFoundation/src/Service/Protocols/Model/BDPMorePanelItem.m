//
//  BDPMorePanelItem.m
//  Timor
//
//  Created by liuxiangxin on 2019/9/19.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "BDPMorePanelItem.h"
#import "BDPMorePanelItem+Private.h"

const NSInteger BDPMorePanelItemPriorityOptional = 100;
const NSInteger BDPMorePanelItemPriorityRequire = 1000;

@interface BDPMorePanelItem ()

@property (nonatomic, copy, readwrite, nonnull) NSString *name;
@property (nonatomic, strong, readwrite, nullable) UIImage *icon;
@property (nonatomic, copy, readwrite, nullable) NSURL*iconURL;
@property (nonatomic, assign, readwrite) BDPMorePanelItemType type;
@property (nonatomic, copy, readwrite, nullable) BDPMorePanelItemAction action;
@property (nonatomic, assign, readwrite) NSUInteger badgeNum;

@end

@implementation BDPMorePanelItem

+ (instancetype)itemWithName:(NSString *)name
                        icon:(UIImage *)icon
                    badgeNum:(NSUInteger)badgeNum 
                      action:(BDPMorePanelItemAction)action
{
    BDPMorePanelItem *item = [[BDPMorePanelItem alloc] initWithType:BDPMorePanelItemTypeCustom
                                                               name:name
                                                               icon:icon
                                                            iconURL:nil
                                                           badgeNum:badgeNum
                                                             action:action];
    
    
    return item;
}

+ (instancetype)itemWithName:(NSString *)name
                     iconURL:(NSURL *)iconURL
                      action:(BDPMorePanelItemAction)action
{
    BDPMorePanelItem *item = [[BDPMorePanelItem alloc] initWithType:BDPMorePanelItemTypeCustom
                                                               name:name
                                                               icon:nil
                                                            iconURL:iconURL
                                                             action:action];

    return item;
    
}

- (instancetype)initWithType:(BDPMorePanelItemType)type
                        name:(NSString *)name
                        icon:(UIImage *)icon
                     iconURL:(NSURL *)iconURL
                      action:(BDPMorePanelItemAction)action
{
    return [self initWithType:type
                         name:name
                         icon:icon
                      iconURL:iconURL
                     badgeNum:0
                       action:action];
}

- (instancetype)initWithType:(BDPMorePanelItemType)type
                        name:(NSString *)name
                        icon:(UIImage *)icon
                     iconURL:(NSURL *)iconURL
                    badgeNum:(NSUInteger)badgeNum
                      action:(BDPMorePanelItemAction)action
{
    self = [super init];
    if (self) {
        _type = type;
        _name = [name copy];
        _icon = icon;
        _iconURL = [iconURL copy];
        _badgeNum = badgeNum;
        _action = [action copy];
    }
    return self;
}

- (void)updateAction:(BDPMorePanelItemAction)action
{
    self.action = action;
}

- (void)setType:(BDPMorePanelItemType)type
{
    _type = type;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    }
    
    return [self hash] == [other hash];
}

- (NSUInteger)hash
{
    return [self.name hash];
}

- (NSString *)description
{
    return self.name;
}

@end
