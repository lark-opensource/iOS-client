//
//  HMDAddressUnit.h
//  Heimdallr
//
//  Created by fengyadong on 2020/11/18.
//

#import <Foundation/Foundation.h>


@interface HMDAddressUnit : NSObject

@property (nonatomic, copy, nullable) NSString *name;/**describe the meaning of the following address to be symbolicated**/
@property (nonatomic, assign) unsigned long long address;/**the following address to be symbolicated**/

- (NSDictionary * _Nullable)unitToDict;

@end

