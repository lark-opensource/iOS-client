//
//  BDUGTokenShareModel.h.m
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

#import "BDUGTokenShareModel.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <TTImage/TTImageInfosModel.h>

#pragma mark - BDUGTokenShareAnalysisResultModel

@implementation BDUGTokenShareAnalysisResultModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        _originDict = dict;
        _panelId = [dict btd_stringValueForKey:@"share_panel_id"];
        _title = [dict btd_stringValueForKey:@"title"];
        _token = [dict btd_stringValueForKey:@"token"];
        _openUrl = [dict btd_stringValueForKey:@"open_url"];
        NSDictionary *userInfo = [dict btd_dictionaryValueForKey:@"share_user_info"];
        _shareUserName = [userInfo btd_stringValueForKey:@"name"];
        _shareUserID = [userInfo btd_stringValueForKey:@"user_id"];
        _shareUserOpenUrl = [userInfo btd_stringValueForKey:@"source_open_url"];
        
        NSArray *pics = [dict btd_arrayValueForKey:@"pics"];
        NSMutableArray *tmpPicArray = [NSMutableArray arrayWithCapacity:pics.count];
        for (NSDictionary *tmpDict in pics) {
            TTImageInfosModel *imageInfo = [[TTImageInfosModel alloc] initWithDictionary:tmpDict];
            [tmpPicArray addObject:imageInfo];
        }
        _pics = [NSArray arrayWithArray:tmpPicArray];
        _picCount = [dict btd_intValueForKey:@"pic_cnt"];
        _mediaType = [dict btd_intValueForKey:@"media_type"];
        _videoDuration = [dict btd_intValueForKey:@"video_duration"];
        _logInfo = [dict btd_dictionaryValueForKey:@"log_info"];
        
        _clientExtra = [dict btd_stringValueForKey:@"client_extra"];
        _buttonText = [dict btd_stringValueForKey:@"button_text"];
    }
    return self;
}

#ifdef DEBUG

- (instancetype)initTestModel {
    if (self = [super init]) {
        _title = @"并不是所有H5页面iewWillAppear 的时候检测 web";
        _shareUserName = @"哈哈哈奥奥哈哈哈哈哈哈哈哈哈哈哈哈";
        TTImageInfosModel *model = [[TTImageInfosModel alloc] initWithURL:@"http://p1.pstatp.com/list/300x196/learning/36390ca0fccd347804de45b4229d68a8.webp"];
        _pics = [NSArray arrayWithObject:model];
    }
    return self;
}

- (instancetype)initTestPhotosModel {
    if (self = [super init]) {
        _title = @"并不是所有H5页面iewWillAppear 的时候检测 web";
        _shareUserName = @"哈哈哈奥奥哈哈哈哈哈哈哈哈哈哈哈哈";
        _mediaType = 2;
        TTImageInfosModel *model = [[TTImageInfosModel alloc] initWithURL:@"http://p1.pstatp.com/list/300x196/learning/36390ca0fccd347804de45b4229d68a8.webp"];
        _pics = [NSArray arrayWithObject:model];
        _picCount = 10;
    }
    return self;
}

#endif

@end
