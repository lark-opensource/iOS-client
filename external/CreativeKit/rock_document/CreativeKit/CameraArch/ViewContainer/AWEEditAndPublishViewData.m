//
//  AWEEditAndPublishViewData.m
//  AWEStudio
//
//  Created by hanxu on 2018/11/16.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEEditAndPublishViewData.h"

@implementation AWEEditAndPublishViewData

- (instancetype)initWithTitle:(NSString *)title
                    imageName:(NSString *)imageName
            selectedImageName:(NSString *)selectedImageName
                        idStr:(NSString *)idStr
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
                  buttonClass:(Class)buttonClass
             extraConfigBlock:(AWEEditAndPublishViewExtraCongifBlock)extraConfigBlock
{
    self = [super init];
    if (self) {
        self.title = title;
        self.imageName = imageName;
        self.selectedImageName = selectedImageName;
        self.actionBlock = actionBlock;
        self.idStr = idStr;
        self.buttonClass = buttonClass;
        self.extraConfigBlock = extraConfigBlock;
    }
    return self;
}

+ (instancetype)dataWithTitle:(NSString *)title
                    imageName:(NSString *)imageName
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
{
    return [[self alloc] initWithTitle:title imageName:imageName selectedImageName:imageName idStr:@"" actionBlock:actionBlock buttonClass:nil extraConfigBlock:nil];
}

+ (instancetype)dataWithTitle:(NSString *)title
                    imageName:(NSString *)imageName
                        idStr:(NSString *)idStr
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
{
    return [[self alloc] initWithTitle:title imageName:imageName selectedImageName:imageName idStr:idStr actionBlock:actionBlock buttonClass:nil extraConfigBlock:nil] ;
}

+ (instancetype)dataWithTitle:(NSString *)title
                    imageName:(NSString *)imageName
                        idStr:(NSString *)idStr
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
                  buttonClass:(Class)buttonClass
{
    return [[self alloc] initWithTitle:title imageName:imageName selectedImageName:imageName idStr:idStr actionBlock:actionBlock buttonClass:buttonClass extraConfigBlock:nil];
}

+ (instancetype)dataWithTitle:(NSString *)title
                    imageName:(NSString *)imageName
                        idStr:(NSString *)idStr
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
                  buttonClass:(Class)buttonClass
             extraConfigBlock:(AWEEditAndPublishViewExtraCongifBlock)extraConfigBlock
{
    return [[self alloc] initWithTitle:title imageName:imageName selectedImageName:imageName idStr:idStr actionBlock:actionBlock buttonClass:buttonClass extraConfigBlock:extraConfigBlock];
}

+ (instancetype)dataWithTitle:(NSString *)title
                    imageName:(NSString *)imageName
            selectedImageName:(NSString *)selectedImageName
                        idStr:(NSString *)idStr
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
                  buttonClass:(Class)buttonClass
             extraConfigBlock:(AWEEditAndPublishViewExtraCongifBlock)extraConfigBlock
{
    return [[self alloc] initWithTitle:title imageName:imageName selectedImageName:selectedImageName idStr:idStr actionBlock:actionBlock buttonClass:buttonClass extraConfigBlock:extraConfigBlock];
}

+ (instancetype)dataWithTitle:(NSString *)title
                        image:(UIImage *)image
                selectedImage:(UIImage *)selectedImage
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
                  buttonClass:(Class)buttonClass
             extraConfigBlock:(AWEEditAndPublishViewExtraCongifBlock)extraConfigBlock {
    AWEEditAndPublishViewData* data = [[AWEEditAndPublishViewData alloc] initWithTitle:title
                                                                             imageName:nil
                                                                     selectedImageName:nil
                                                                                 idStr:nil
                                                                           actionBlock:actionBlock
                                                                           buttonClass:buttonClass
                                                                      extraConfigBlock:extraConfigBlock];
    data.image = image;
    data.selectedImage = selectedImage;
    return data;
}

+ (instancetype)dataWithTitle:(NSString *)title
                        image:(UIImage *)image
                selectedImage:(UIImage *)selectedImage
                         show:(BOOL)shouldShow
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
                  buttonClass:(Class)buttonClass
             extraConfigBlock:(AWEEditAndPublishViewExtraCongifBlock)extraConfigBlock {
    AWEEditAndPublishViewData* data = [[AWEEditAndPublishViewData alloc] initWithTitle:title
                                                                             imageName:nil
                                                                     selectedImageName:nil
                                                                                 idStr:nil
                                                                           actionBlock:actionBlock
                                                                           buttonClass:buttonClass
                                                                      extraConfigBlock:extraConfigBlock];
    data.image = image;
    data.selectedImage = selectedImage;
    data.shouldShow = shouldShow;
    return data;
}

@end
