//
//  BulletXVCConfiguration.m
//  Bullet-Pods-AwemeLite
//
//  Created by 王丹阳 on 2020/11/2.
//

#import "BDXPopupSchemaParam.h"
#import <BDXServiceCenter/BDXContext.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSData+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>

@implementation BDXPopupSchemaParam

+ (instancetype)paramWithDictionary:(NSDictionary *)dictionary
{
    BDXPopupSchemaParam *config = [[BDXPopupSchemaParam alloc] init];
    [config updateWithDictionary:dictionary];
    return config;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
    [super updateWithDictionary:dict];
    self.preferViewController = nil;
    
    NSString *enterType = [dict btd_stringValueForKey:@"popup_enter_type"];
    if (enterType) {
        if ([enterType isEqualToString:@"bottom"]) {
            self.type = BDXPopupTypeBottomIn;
        } else if ([enterType isEqualToString:@"right"]) {
            self.type = BDXPopupTypeRightIn;
        } else {
            self.type = BDXPopupTypeDialog;
        }
    } else {
        self.type = [dict btd_intValueForKey:@"type"];
    }
    
    __auto_type keyboardStyleValue = dict[@"keyboard_style"];
    NSDictionary *keyboardStyleDict = nil;
    if ([keyboardStyleValue isKindOfClass:NSDictionary.class]) {
        keyboardStyleDict = keyboardStyleValue;
    } else if ([keyboardStyleValue isKindOfClass:NSString.class]) {
        keyboardStyleDict = [(NSString *)keyboardStyleValue btd_jsonDictionary];
    }
    self.keyboardOffset = [keyboardStyleDict btd_numberValueForKey:@"bottom"];

    __auto_type styleValue = dict[@"style"];
    NSDictionary *styleDict = nil;
    if ([styleValue isKindOfClass:NSDictionary.class]) {
        styleDict = styleValue;
    } else if ([styleValue isKindOfClass:NSString.class]) {
        styleDict = [(NSString *)styleValue btd_jsonDictionary];
    }
    self.topOffset = [styleDict btd_numberValueForKey:@"top"];
    self.bottomOffset = [styleDict btd_numberValueForKey:@"bottom"];

    self.width = [dict btd_numberValueForKey:@"width" default:nil];
    self.height = [dict btd_numberValueForKey:@"height" default:nil];

    self.widthPercent = [dict btd_integerValueForKey:@"width_percent" default:100];
    if (self.widthPercent > 100 || self.widthPercent < 0) {
        self.widthPercent = 100;
    }

    self.heightPercent = [dict btd_integerValueForKey:@"height_percent" default:100];
    if (self.heightPercent > 100 || self.heightPercent < 0) {
        self.heightPercent = 100;
    }

    self.aspectRatio = [dict btd_numberValueForKey:@"aspect_ratio" default:nil];
    self.radius = [dict btd_numberValueForKey:@"radius" default:nil];
    self.maskColorString = [dict btd_stringValueForKey:@"mask_color"];
    if (self.maskColorString.length && self.maskColorString.length != 6 && self.maskColorString.length != 8) {
        self.maskColorString = [[self.maskColorString btd_stringByURLDecode] substringWithRange:NSMakeRange(1, self.maskColorString.length - 1)];
    }

    // BulletXPopupItem use btd_colorWithHexString: which require RGBA, but
    // Android RD only support ARGB
    NSString *RGBAColorString = ({
        __auto_type ARGBColorString = [dict btd_stringValueForKey:@"argb_mask_color"];
        ARGBColorString = [ARGBColorString stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSString *result = nil;
        if (ARGBColorString.length == 8) {
            __auto_type RGBPart = [ARGBColorString substringFromIndex:2];
            __auto_type AlphaPart = [ARGBColorString substringToIndex:2];
            result = [RGBPart stringByAppendingString:AlphaPart];
        }
        result;
    });
    if (RGBAColorString.length > 0) {
        self.maskColorString = RGBAColorString;
    }

    self.closeByMask = [dict btd_boolValueForKey:@"close_by_mask" default:NO];
    self.closeByGesture = [dict btd_boolValueForKey:@"close_by_gesture" default:NO];
    self.maskCanCloseUntilLoaded = [dict btd_boolValueForKey:@"mask_close_until_loaded" default:NO];

    self.originContainerID = [dict btd_stringValueForKey:@"origin_container_id"];
    self.behavior = [dict btd_intValueForKey:@"trigger_origin"];

    self.dragByGesture = [dict btd_boolValueForKey:@"drag_by_gesture" default:NO];
    // 仅对BottomIn支持drag
    if (self.type != BDXPopupTypeBottomIn) {
        self.dragByGesture = NO;
    }
    self.dragBack = [dict btd_boolValueForKey:@"drag_back" default:NO];
    self.dragFollowGesture = [dict btd_boolValueForKey:@"drag_follow_gesture" default:YES];
    self.dragHeight = [dict btd_numberValueForKey:@"drag_height" default:nil];
    self.dragHeightPercent = [dict btd_integerValueForKey:@"drag_height_percent" default:100];
    if (self.dragHeightPercent > 100 || self.dragHeightPercent < 0) {
        self.dragHeightPercent = 100;
    }
}

@end
