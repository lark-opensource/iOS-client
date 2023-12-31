//
//  BDXPageSchemaParam.m
//  BDXContainer
//
//  Created by bill on 2021/3/14.
//

#import "BDXPageSchemaParam.h"
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSData+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>

@implementation BDXPageSchemaParam

+ (instancetype)paramWithDictionary:(NSDictionary *)dictionary
{
    BDXPageSchemaParam *config = [[BDXPageSchemaParam alloc] init];
    [config updateWithDictionary:dictionary];
    return config;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
    [super updateWithDictionary:dict];

    self.disableSwipe = [dict btd_boolValueForKey:@"disable_swipe" default:NO];
    self.hideNavBar = [dict btd_boolValueForKey:@"hide_nav_bar" default:NO];
    self.hideStatusBar = [dict btd_boolValueForKey:@"hide_status_bar" default:NO];
    self.showMoreButton = [dict btd_boolValueForKey:@"show_more_button" default:NO];
    self.copyLinkAction = [dict btd_boolValueForKey:@"copy_link_action" default:NO];
    self.transStatusBar = [dict btd_boolValueForKey:@"trans_status_bar" default:NO];
    if([dict btd_floatValueForKey:@"preferred_width"] >= 1.f && [dict btd_floatValueForKey:@"preferred_height"] >= 1.f){
        self.preferredSize = CGSizeMake([dict btd_floatValueForKey:@"preferred_width"], [dict btd_floatValueForKey:@"preferred_height"]);
    }
    self.title = [dict btd_stringValueForKey:@"title"];

    if ([dict[@"title_color"] isKindOfClass:NSString.class]) {
        self.titleColor = [UIColor btd_colorWithHexString:dict[@"title_color"]];
    }

    if ([dict[@"nav_bar_color"] isKindOfClass:NSString.class]) {
        self.navBarColor = [UIColor btd_colorWithHexString:dict[@"nav_bar_color"]];
    }

    __auto_type navBtnType = [dict btd_integerValueForKey:@"nav_btn_type"];
    if (navBtnType) {
        if (navBtnType == 1) {
            self.navigationButtonType = BDXNavigationButtonTypeReport;
        } else if (navBtnType == 2) {
            self.navigationButtonType = BDXNavigationButtonTypeShare;
        } else {
            self.navigationButtonType = BDXNavigationButtonTypeNone;
        }
    } else {
        __auto_type navBtnTypeString = [dict btd_stringValueForKey:@"nav_btn_type"];
        if ([navBtnTypeString isEqualToString:@"share"]) {
            self.navigationButtonType = BDXNavigationButtonTypeShare;
        } else if (navBtnTypeString) {
            self.navigationButtonType = BDXNavigationButtonTypeReport;
        } else {
            self.navigationButtonType = BDXNavigationButtonTypeNone;
        }
    }
}

@end
