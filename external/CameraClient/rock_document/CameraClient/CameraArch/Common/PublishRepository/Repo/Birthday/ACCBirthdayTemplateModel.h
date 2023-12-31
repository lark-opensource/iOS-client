//
//  ACCBirthdayTemplateModel.h
//  AWEFriends-Pods-Aweme
//
//  Created by shaohua yang on 11/16/20.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEURLModel;

@interface ACCBirthdayTemplateModel : MTLModel<MTLJSONSerializing>

@property (nonatomic) NSInteger effectId;
@property (nonatomic) AWEURLModel *icon;
@property (nonatomic) AWEURLModel *previewAddr;
@property (nonatomic) NSString *title;

@end

NS_ASSUME_NONNULL_END
