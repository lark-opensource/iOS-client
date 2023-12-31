//
//  ACCRecorderPendantView.h
//  Aweme
//
//  Created by HuangHongsen on 2021/11/2.
//

#import <UIKit/UIKit.h>
#import "ACCRecorderPendantDefines.h"

@class ACCRecorderPendantView;
@protocol ACCRecorderPendantViewDelegate <NSObject>

- (void)userDidClosePendantView:(ACCRecorderPendantView * _Nonnull)pendantView;

- (void)userDidTapOnPendantView:(ACCRecorderPendantView * _Nonnull)pendantView;

@end

@interface ACCRecorderPendantView : UIView

@property (nonatomic, weak, nullable) id<ACCRecorderPendantViewDelegate> delegate;
@property (nonatomic, assign) BOOL resourceLoaded;

- (void)loadResourceWithType:(ACCRecorderPendantResourceType)resourceType
                     urlList:(NSArray * _Nullable)iconURLList
                  lottieJSON:(NSDictionary * _Nullable)json
                  completion:(void (^)(BOOL))completion;

+ (CGSize)pendentSize;

@end
