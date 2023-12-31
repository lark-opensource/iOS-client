//
//  ACCRepoDraftFeedModelProtocol.h
//  CameraClient
//
//  Created by ZZZ on 2021/8/24.
//

@protocol ACCRepoDraftFeedModelProtocol <NSObject>

@required

@property (nonatomic, copy) NSString *draftFeedPlayerFrame;

@property (nonatomic, strong) NSNumber *quickPublishEnabled;

@property (nonatomic, copy) NSString *nextButtonTitle;

@end
