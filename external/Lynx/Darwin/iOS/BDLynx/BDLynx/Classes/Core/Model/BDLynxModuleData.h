//
//  BDLynxModuleData.h
//  BDLynx
//
//  Created by 林茂森 on 2020/6/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDLynxModuleData : NSObject

@property(nonatomic, copy) NSString *groupID;
@property(nonatomic, copy) NSString *cardID;
@property(nonatomic, copy) NSString *storagePath;
@property(nonatomic, copy) NSString *verifyURL;
@property(nonatomic, copy) NSString *publishVersion;
@property(nonatomic, strong) NSDictionary *customFileds;
@property(nonatomic, assign) BOOL iSOneCard;

@end

NS_ASSUME_NONNULL_END
