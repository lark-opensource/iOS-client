//
//  TMAStickerInputModel.h
//  OPPluginBiz
//
//  Created by houjihu on 2018/9/14.
//

#import <JSONModel/JSONModel.h>

typedef NS_ENUM(NSUInteger, TMAStickerInputEventType) {
    TMAStickerInputEventTypePicSelect,
    TMAStickerInputEventTypeModelSelect,
    TMAStickerInputEventTypePublish,
    TMAStickerInputEventTypeHide,
};

@protocol TMAStickerInputAtModel;

@interface TMAStickerInputAtModel : JSONModel
/// openID
@property (nonatomic, copy, nullable) NSString *id;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) NSInteger length;
/// 从Lark native界面获取的是larkID，请求接口转化成openID传给js，从js获取到的是openID，故默认为NO
@property (nonatomic, copy, nullable) NSString *larkID;
@end

@protocol TMAStickerInputUserSelectModel;

@interface TMAStickerInputUserSelectModel : JSONModel
@property (nonatomic, copy, nullable) NSArray<NSString *> *items;
@property (nonatomic, copy, nullable) NSString *data;
@end

@interface TMAStickerInputModel : JSONModel

@property (nonatomic, strong, nullable) NSArray<NSString *> *picture;
@property (nonatomic, strong, nullable) NSArray<TMAStickerInputAtModel> *at;
@property (nonatomic, copy, nullable) NSString *content;
@property (nonatomic, copy, nullable) NSString *placeholder;
@property (nonatomic, strong, nullable) TMAStickerInputUserSelectModel *userModelSelect;
@property (nonatomic, copy, nullable) NSString *avatar;
@property (nonatomic, assign) BOOL showEmoji;
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, assign) BOOL enablesReturnKey;
@property (nonatomic, assign) BOOL externalContact;

@property (nonatomic, copy) NSString *confirmType;

- (NSDictionary *)eventDataWithType:(TMAStickerInputEventType)type;

@end
