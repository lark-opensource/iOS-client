//
//  AWEEditAndPublishViewData.h
//  AWEStudio
//
//  Created by hanxu on 2018/11/16.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AWEEditActionItemView;

typedef void(^AWEEditAndPublishViewActionBlock)(UIView *editAndPublishView, AWEEditActionItemView *itemView);
typedef void(^AWEEditAndPublishViewExtraCongifBlock)(AWEEditActionItemView *itemView);

@interface AWEEditAndPublishViewData : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, copy) NSString *selectedImageName;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *selectedImage;
@property (nonatomic, copy) AWEEditAndPublishViewActionBlock actionBlock;
@property (nonatomic, strong) Class buttonClass;
@property (nonatomic, strong) NSString *idStr;
@property (nonatomic, copy) AWEEditAndPublishViewExtraCongifBlock extraConfigBlock;
@property (nonatomic, assign) BOOL shouldShow;

+ (instancetype)dataWithTitle:(NSString *)title
                    imageName:(NSString *)imageName
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock;

+ (instancetype)dataWithTitle:(NSString *)title
                    imageName:(NSString *)imageName
                        idStr:(NSString *)idStr
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock;

+ (instancetype)dataWithTitle:(NSString *)title
                    imageName:(NSString *)imageName
                        idStr:(NSString *)idStr
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
                  buttonClass:(Class)buttonClass;

+ (instancetype)dataWithTitle:(NSString *)title
                    imageName:(NSString *)imageName
                        idStr:(NSString *)idStr
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
                  buttonClass:(Class)buttonClass
             extraConfigBlock:(AWEEditAndPublishViewExtraCongifBlock)extraConfigBlock;

+ (instancetype)dataWithTitle:(NSString *)title
                    imageName:(NSString *)imageName
            selectedImageName:(NSString *)selectedImageName
                        idStr:(NSString *)idStr
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
                  buttonClass:(Class)buttonClass
             extraConfigBlock:(AWEEditAndPublishViewExtraCongifBlock)extraConfigBlock;

+ (instancetype)dataWithTitle:(NSString *)title
                        image:(UIImage *)image
                selectedImage:(UIImage *)selectedImage
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
                  buttonClass:(Class)buttonClass
             extraConfigBlock:(AWEEditAndPublishViewExtraCongifBlock)extraConfigBlock;

+ (instancetype)dataWithTitle:(NSString *)title
                        image:(UIImage *)image
                selectedImage:(UIImage *)selectedImage
                         show:(BOOL)shouldShow
                  actionBlock:(AWEEditAndPublishViewActionBlock)actionBlock
                  buttonClass:(Class)buttonClass
             extraConfigBlock:(AWEEditAndPublishViewExtraCongifBlock)extraConfigBlock;

@end
