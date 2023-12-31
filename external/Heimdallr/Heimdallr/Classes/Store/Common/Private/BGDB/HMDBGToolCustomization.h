//
//  HMDBGToolCustomization.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/3/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HMDBGToolCustomization <NSObject>

// confrom to this protocol
// return nil to use default property type
// return customized string to use your type
+ (NSString * _Nullable)HMD_BGTool_overrideIvarTypeForIvarNameWithoutPrefixUnderscore:(NSString *_Nonnull)key;

@end

NS_ASSUME_NONNULL_END
