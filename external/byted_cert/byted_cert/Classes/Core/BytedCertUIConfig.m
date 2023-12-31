//
//  BytedCertUIConfig.m
//  BytedCert
//
//  Created by LiuChundian on 2019/3/23.
//  Copyright © 2019年 bytedance. All rights reserved.
//

#import "BytedCertUIConfig.h"
#import "BytedCertInterface.h"
#import "BDCTAdditions.h"
#import <ByteDanceKit/UIColor+BTDAdditions.h>


@implementation BytedCertUIConfig

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static BytedCertUIConfig *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[BytedCertUIConfig alloc] init];
    });

    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        if (@available(iOS 13.0, *)) {
            self.statusBarStyle = UIStatusBarStyleDarkContent;
        } else {
            self.statusBarStyle = UIStatusBarStyleDefault;
        }

        self.primaryColor = [UIColor btd_colorWithHexString:@"#2A90D7"];
        self.backgroundColor = [UIColor whiteColor];
        self.secondBackgroundColor = [UIColor btd_colorWithHexString:@"#E8E8E8"];
        self.textColor = [UIColor blackColor];
        self.secondTextColor = [UIColor blackColor];

        self.circleColor = self.secondBackgroundColor;

        self.readNumberLabelFont = [UIFont fontWithName:@"PingFangSC-Semibold" size:48];
        self.actionCountTipLabelFont = [UIFont fontWithName:@"PingFangSC-Regular" size:20];

        self.faceDetectionProgressStrokeWidth = 5.0f;

        self.backBtnImage = [UIImage bdct_imageWithName:@"Return_Black"];
    }
    return self;
}

- (void)setPrimaryColor:(UIColor *)primaryColor {
    _primaryColor = _timeColor = primaryColor;
}

- (void)setTimeColor:(UIColor *)timeColor {
    _timeColor = _primaryColor = timeColor;
}

@end


@implementation BytedCertUIConfigMaker : NSObject

- (BytedCertUIConfigMaker * (^)(UIColor *))primaryColor {
    return ^(UIColor *primaryColor) {
        BytedCertUIConfig.sharedInstance.primaryColor = primaryColor;
        return self;
    };
}

- (BytedCertUIConfigMaker * (^)(UIColor *))backgroundColor {
    return ^(UIColor *backgroundColor) {
        BytedCertUIConfig.sharedInstance.backgroundColor = backgroundColor;
        return self;
    };
}

- (BytedCertUIConfigMaker * (^)(UIColor *))secondBackgroundColor {
    return ^(UIColor *secondBackgroundColor) {
        BytedCertUIConfig.sharedInstance.secondBackgroundColor = secondBackgroundColor;
        return self;
    };
}

- (BytedCertUIConfigMaker * (^)(UIColor *))textColor {
    return ^(UIColor *textColor) {
        BytedCertUIConfig.sharedInstance.textColor = textColor;
        return self;
    };
}

- (BytedCertUIConfigMaker * (^)(UIColor *))secondTextColor {
    return ^(UIColor *secondTextColor) {
        BytedCertUIConfig.sharedInstance.secondTextColor = secondTextColor;
        return self;
    };
}

- (BytedCertUIConfigMaker * (^)(UIFont *))actionLabelFont {
    return ^(UIFont *actionLabelFont) {
        BytedCertUIConfig.sharedInstance.actionLabelFont = actionLabelFont;
        return self;
    };
}

- (BytedCertUIConfigMaker * (^)(UIFont *))actionCountTipLabelFont {
    return ^(UIFont *actionCountTipLabelFont) {
        BytedCertUIConfig.sharedInstance.actionCountTipLabelFont = actionCountTipLabelFont;
        return self;
    };
}

- (BytedCertUIConfigMaker * (^)(UIImage *))faceDetectionBgImage {
    return ^(UIImage *faceDetectionBgImage) {
        BytedCertUIConfig.sharedInstance.faceDetectionBgImage = faceDetectionBgImage;
        return self;
    };
}

- (BytedCertUIConfigMaker * (^)(UIImage *))backBtnImage {
    return ^(UIImage *backBtnImage) {
        BytedCertUIConfig.sharedInstance.backBtnImage = backBtnImage;
        return self;
    };
}

- (BytedCertUIConfigMaker * (^)(BOOL))isDarkMode {
    return ^(BOOL isDarkMode) {
        BytedCertUIConfig.sharedInstance.isDarkMode = isDarkMode;
        return self;
    };
}

@end
