//
//  BDRuleParameterBuilderProtocol.h
//  Pods
//
//  Created by WangKun on 2021/12/9.
//

#ifndef BDRuleParameterBuilderProtocol_h
#define BDRuleParameterBuilderProtocol_h

@protocol BDRuleParameterBuilderProtocol<NSObject>

- (id)generateValueFor:(NSString *)key
                 extra:(NSDictionary *)extra
                 error:(NSError **)error;

@end


#endif /* BDRuleParameterBuilderProtocol_h */
