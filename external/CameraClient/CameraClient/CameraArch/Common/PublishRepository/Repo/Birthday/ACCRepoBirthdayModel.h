//
//  ACCRepoBirthdayModel.h
//  CameraClient-Pods-Aweme
//
//  Created by shaohua yang on 11/30/20.
//

#import <Foundation/Foundation.h>
#import "ACCBirthdayTemplateModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@protocol ACCUserModelProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoBirthdayModel : NSObject

// 是否是生日祝福投稿 - 草稿
@property (nonatomic, copy) NSData *birthdayTemplatesJson;

// derived properties - 只存在于内存
@property (nonatomic, readonly) BOOL isBirthdayPost;
@property (nonatomic, copy) NSArray<ACCBirthdayTemplateModel *> *birthdayTemplates;


@property (nonatomic, readonly) ACCBirthdayTemplateModel *current;
@property (nonatomic, readonly) ACCBirthdayTemplateModel *next;

@property (nonatomic, strong) id<ACCUserModelProtocol> atUser;
@property (nonatomic, assign) BOOL isIMBirthdayPost;
@property (nonatomic, assign) BOOL isDraftEnable; //  后续支持发日常，需要草稿箱

@end

@interface AWEVideoPublishViewModel (RepoBirthday)
 
@property (nonatomic, strong, readonly) ACCRepoBirthdayModel *repoBirthday;
 
@end

NS_ASSUME_NONNULL_END
