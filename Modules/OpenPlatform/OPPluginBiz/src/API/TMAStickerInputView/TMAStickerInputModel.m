//
//  TMAStickerInputModel.m
//  OPPluginBiz
//
//  Created by houjihu on 2018/9/14.
//

#import "TMAStickerInputModel.h"

@implementation TMAStickerInputAtModel

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    if ([propertyName isEqualToString:NSStringFromSelector(@selector(larkID))]) {
        return YES;
    }
    return NO;
}

@end

@implementation TMAStickerInputUserSelectModel

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation TMAStickerInputModel

- (NSDictionary *)eventDataWithType:(TMAStickerInputEventType)type {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    NSString *eventName = [[self class] eventNameForType:type];
    data[@"eventName"] = eventName;
    NSString *dataKey = @"data";
    switch (type) {
        case TMAStickerInputEventTypePicSelect:
        case TMAStickerInputEventTypeModelSelect:
        case TMAStickerInputEventTypePublish:
        case TMAStickerInputEventTypeHide: {
            NSMutableDictionary *subdata = [[NSMutableDictionary alloc] init];
            subdata[@"picture"] = self.picture;
            subdata[@"at"] = [TMAStickerInputAtModel arrayOfDictionariesFromModels:self.at];
            subdata[@"userModelSelect"] = self.userModelSelect.data;
            subdata[@"content"] = self.content;
            data[dataKey] = subdata;
            break;
        }
    }
    return data;
}

+ (NSString *)eventNameForType:(TMAStickerInputEventType)type {
    NSString *eventName;
    switch (type) {
        case TMAStickerInputEventTypePicSelect: {
            eventName = @"picSelect";
            break;
        }
        case TMAStickerInputEventTypeModelSelect: {
            eventName = @"modelSelect";
            break;
        }
        case TMAStickerInputEventTypePublish: {
            eventName = @"publish";
            break;
        }
        case TMAStickerInputEventTypeHide: {
            eventName = @"hide";
            break;
        }
    }
    return eventName;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
