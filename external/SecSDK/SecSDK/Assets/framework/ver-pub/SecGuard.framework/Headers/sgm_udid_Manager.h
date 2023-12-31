//
//  FPUtil.h
//  Pods
//
//  Created by moqianqian on 2020/4/25.
//

#import <Foundation/Foundation.h>

NSDictionary* sgm_UDIDBaseCollect(void);

NSString* sgm_getUDID(NSString *service, NSString *account);

bool sgm_setUDID(NSString *service, NSString *account, NSString *UDID);

