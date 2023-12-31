//
//  HMDJSONable.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/29.
//

#import <Foundation/Foundation.h>

@protocol HMDJSONable <NSObject>
- (NSDictionary * _Nullable)jsonObject;
@end
