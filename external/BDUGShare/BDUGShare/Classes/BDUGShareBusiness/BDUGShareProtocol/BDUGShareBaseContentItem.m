//
//  BDUGShareBaseContentItem.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/4/16.
//

#import "BDUGShareBaseContentItem.h"
#import "BDUGShareDataModel.h"
#import <objc/runtime.h>

@implementation BDUGShareBaseContentItem

//todo： @synthesize单独成行。
@synthesize title = _title, desc = _desc, defaultShareType = _defaultShareType, webPageUrl = _webPageUrl,
groupID = _groupID, clickMode = _clickMode, image = _image, thumbImage = _thumbImage, imageUrl = _imageUrl, contentItemType = _contentItemType, contentTitle = _contentTitle, activityImageName = _activityImageName, activityImage = _activityImage, videoURL = _videoURL, serverDataModel = _serverDataModel, resourceSandboxPathString = _resourceSandboxPathString, channelString = _channelString;

- (void)convertfromModel:(BDUGShareDataItemModel *)model {
    self.serverDataModel = model;
    if (model.title.length > 0) {
        self.title = model.title;
    }
    if (model.desc.length > 0) {
        self.desc = model.desc;
    }
    if (model.shareUrl.length > 0) {
        self.webPageUrl = model.shareUrl;
    }
    if (model.imageUrl.length > 0) {
        self.imageUrl = model.imageUrl;
    }
    if (model.videoURL.length > 0) {
        self.videoURL = model.videoURL;
    }
}

- (BOOL)imageShareValid {
    return self.image != nil || self.imageUrl.length > 0;
}

- (BOOL)videoShareValid {
    return self.videoURL.length > 0 || self.resourceSandboxPathString.length > 0;
}

#pragma mark - copy method

- (void)convertFromAnotherContentItem:(BDUGShareBaseContentItem *)contentItem
{
    //遍历父类。
    [contentItem.class enumerateClasses:^(__unsafe_unretained Class c, BOOL *stop) {
        unsigned int propertyCount = 0;
        objc_property_t *propertyArray = class_copyPropertyList(c, &propertyCount);
        for (int i = 0; i < propertyCount; i++) {
            objc_property_t  property = propertyArray[i];
            const char * propertyName = property_getName(property);
            NSString * key = [NSString stringWithUTF8String:propertyName];
            id value = [contentItem valueForKey:key];
            
            // 过滤掉系统自动添加的元素
            if ([key isEqualToString:@"hash"]
                || [key isEqualToString:@"superclass"]
                || [key isEqualToString:@"description"]
                || [key isEqualToString:@"debugDescription"]) {
                continue;
            }
            
            //如果没有key会不会崩溃。
            if ([value respondsToSelector:@selector(copyWithZone:)]) {
                //5. 设置属性值
                [self setValue:[value copy] forKey:key];
            } else {
                [self setValue:value forKey:key];
            }
        }
        free(propertyArray);
    }];
}

typedef void (^BDUGClassesEnumeration)(Class c, BOOL *stop);

+ (void)enumerateClasses:(BDUGClassesEnumeration)enumeration {
    // 1.没有block就直接返回
    if (enumeration == nil) return;
    
    // 2.停止遍历的标记
    BOOL stop = NO;
    
    // 3.当前正在遍历的类
    Class c = self;
    
    // 4.开始遍历每一个类
    while (c && !stop) {
        if (c == [BDUGShareBaseContentItem class]) {
            //只遍历当前类的属性。
            enumeration(c, &stop);
            break;
        }
        if (c == [NSObject class]) {
            break;
        }
        // 4.2.使用runtime获得父类
        c = class_getSuperclass(c);
    }
}

@end

