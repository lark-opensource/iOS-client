//
//  ACCEditBarItemExtraData.h
//  CameraClient
//
//  Created by wishes on 2020/6/2.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEEditAndPublishViewData+Business.h>
#import <CreativeKit/AWEEditAndPublishViewData.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditBarItemExtraData : NSObject

@property (nonatomic, strong, readonly) Class buttonClass;

@property (nonatomic, assign, readonly)  AWEEditAndPublishViewDataType type;

- (instancetype)initWithButtonClass:(nullable Class)buttonClass
                               type:(AWEEditAndPublishViewDataType)type;

@end

NS_ASSUME_NONNULL_END
