//
//  CJPayIAPFailPopupConfigModel.h
//  Aweme
//
//  Created by bytedance on 2022/12/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayIAPFailPopupConfigModel : NSObject

@property (nonatomic, copy) NSArray *sk1Network;
@property (nonatomic, copy) NSArray *sk2Network;
@property (nonatomic, copy) NSArray *sk1Others;
@property (nonatomic, copy) NSArray *sk2Others;
@property (nonatomic, copy) NSString *linkChatUrl;
@property (nonatomic, copy) NSString *contentNetwork;
@property (nonatomic, copy) NSString *contentOthers;
@property (nonatomic, copy) NSString *titleNetwork;
@property (nonatomic, copy) NSString *titleOthers;
@property (nonatomic, assign) CFAbsoluteTime startTime;
@property (nonatomic, assign) int merchantFrequency;
@property (nonatomic, assign) int orderFrequency;

@end

NS_ASSUME_NONNULL_END
