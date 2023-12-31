//
//  HMTools.h
//  Hermas
//
//  Created by 崔晓兵 on 7/6/2022.
//

#import <Foundation/Foundation.h>
#include <vector>
#include <map>
#include <string>
#include <memory>

namespace hermas {

NSString* _Nullable stringWithDictionary(NSDictionary * _Nonnull dic);

NSDictionary* _Nullable dictionaryWithJsonString(NSString * _Nonnull jsonString);

std::map<int, int> convertNSDictionayToIntTypeMap(NSDictionary * _Nonnull dic);

std::vector<std::string> vectorWithNSArray(NSArray<NSString*> * _Nonnull arr);

std::string stringWithNSArray(NSArray<NSString*> * _Nonnull arr);

std::map<std::string, std::vector<std::string>> mapWithNSDictionary(NSDictionary * _Nonnull dic);

std::map<std::string, double> mapWithDoubleNSDictionary(NSDictionary * _Nonnull dic);

bool isDictionaryEmpty(NSDictionary * _Nullable dict);

}
