////
////  SGMResultSet.h
////  SecGuard
////
////  Created by jianghaowne on 2019/5/15.
////
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SGMDataBase;
@class SGMStatement;

@interface SGMResultSet : NSObject

@property (nonatomic, retain, nullable) SGMDataBase *parentDB;

@property (atomic, retain, nullable) NSString *query;

@property (readonly) NSMutableDictionary *columnNameToIndexMap;

@property (atomic, retain, nullable) SGMStatement *statement;

+ (instancetype)resultSetWithStatement:(SGMStatement *)statement usingParentDatabase:(SGMDataBase *)aDB;

- (void)close;

- (BOOL)next;

- (BOOL)nextWithError:(NSError * _Nullable __autoreleasing *)outErr;

//- (BOOL)hasAnotherRow;
//
//@property (nonatomic, readonly) int columnCount;
//
//- (int)columnIndexForName:(NSString*)columnName;
//
//- (NSString * _Nullable)columnNameForIndex:(int)columnIdx;
//
//- (int)intForColumn:(NSString*)columnName;
//
//- (int)intForColumnIndex:(int)columnIdx;
//
//- (long)longForColumn:(NSString*)columnName;
//
//- (long)longForColumnIndex:(int)columnIdx;
//
///** Result set `long long int` value for column.
//
// @param columnName `NSString` value of the name of the column.
//
// @return `long long int` value of the result set's column.
// */
//
//- (long long int)longLongIntForColumn:(NSString*)columnName;
//
///** Result set `long long int` value for column.
//
// @param columnIdx Zero-based index for column.
//
// @return `long long int` value of the result set's column.
// */
//
//- (long long int)longLongIntForColumnIndex:(int)columnIdx;
//
///** Result set `unsigned long long int` value for column.
//
// @param columnName `NSString` value of the name of the column.
//
// @return `unsigned long long int` value of the result set's column.
// */
//
//- (unsigned long long int)unsignedLongLongIntForColumn:(NSString*)columnName;
//
///** Result set `unsigned long long int` value for column.
//
// @param columnIdx Zero-based index for column.
//
// @return `unsigned long long int` value of the result set's column.
// */
//
//- (unsigned long long int)unsignedLongLongIntForColumnIndex:(int)columnIdx;
//
///** Result set `BOOL` value for column.
//
// @param columnName `NSString` value of the name of the column.
//
// @return `BOOL` value of the result set's column.
// */
//
//- (BOOL)boolForColumn:(NSString*)columnName;
//
///** Result set `BOOL` value for column.
//
// @param columnIdx Zero-based index for column.
//
// @return `BOOL` value of the result set's column.
// */
//
//- (BOOL)boolForColumnIndex:(int)columnIdx;
//
///** Result set `double` value for column.
//
// @param columnName `NSString` value of the name of the column.
//
// @return `double` value of the result set's column.
//
// */
//
//- (double)doubleForColumn:(NSString*)columnName;
//
///** Result set `double` value for column.
//
// @param columnIdx Zero-based index for column.
//
// @return `double` value of the result set's column.
//
// */
//
//- (double)doubleForColumnIndex:(int)columnIdx;
//
///** Result set `NSString` value for column.
//
// @param columnName `NSString` value of the name of the column.
//
// @return String value of the result set's column.
//
// */
//
//- (NSString * _Nullable)stringForColumn:(NSString*)columnName;
//
///** Result set `NSString` value for column.
//
// @param columnIdx Zero-based index for column.
//
// @return String value of the result set's column.
// */
//
//- (NSString * _Nullable)stringForColumnIndex:(int)columnIdx;
//
///** Result set `NSDate` value for column.
//
// @param columnName `NSString` value of the name of the column.
//
// @return Date value of the result set's column.
// */
//
//- (NSDate * _Nullable)dateForColumn:(NSString*)columnName;
//
///** Result set `NSDate` value for column.
//
// @param columnIdx Zero-based index for column.
//
// @return Date value of the result set's column.
//
// */
//
//- (NSDate * _Nullable)dateForColumnIndex:(int)columnIdx;
//
///** Result set `NSData` value for column.
//
// This is useful when storing binary data in table (such as image or the like).
//
// @param columnName `NSString` value of the name of the column.
//
// @return Data value of the result set's column.
//
// */
//
//- (NSData * _Nullable)dataForColumn:(NSString*)columnName;
//
///** Result set `NSData` value for column.
//
// @param columnIdx Zero-based index for column.
//
// @return Data value of the result set's column.
// */
//
//- (NSData * _Nullable)dataForColumnIndex:(int)columnIdx;
//
///** Result set `(const unsigned char *)` value for column.
//
// @param columnName `NSString` value of the name of the column.
//
// @return `(const unsigned char *)` value of the result set's column.
// */
//
//- (const unsigned char * _Nullable)UTF8StringForColumn:(NSString*)columnName;
//
//- (const unsigned char * _Nullable)UTF8StringForColumnName:(NSString*)columnName __deprecated_msg("Use UTF8StringForColumn instead");
//
///** Result set `(const unsigned char *)` value for column.
//
// @param columnIdx Zero-based index for column.
//
// @return `(const unsigned char *)` value of the result set's column.
// */
//
//- (const unsigned char * _Nullable)UTF8StringForColumnIndex:(int)columnIdx;
//
///** Result set object for column.
//
// @param columnName Name of the column.
//
// @return Either `NSNumber`, `NSString`, `NSData`, or `NSNull`. If the column was `NULL`, this returns `[NSNull null]` object.
//
// @see objectForKeyedSubscript:
// */
//
//- (id _Nullable)objectForColumn:(NSString*)columnName;
//
//- (id _Nullable)objectForColumnName:(NSString*)columnName __deprecated_msg("Use objectForColumn instead");
//
///** Result set object for column.
//
// @param columnIdx Zero-based index for column.
//
// @return Either `NSNumber`, `NSString`, `NSData`, or `NSNull`. If the column was `NULL`, this returns `[NSNull null]` object.
//
// @see objectAtIndexedSubscript:
// */
//
//- (id _Nullable)objectForColumnIndex:(int)columnIdx;
//
///** Result set object for column.
//
// This method allows the use of the "boxed" syntax supported in Modern Objective-C. For example, by defining this method, the following syntax is now supported:
//
// id result = rs[@"employee_name"];
//
// This simplified syntax is equivalent to calling:
//
// id result = [rs objectForKeyedSubscript:@"employee_name"];
//
// which is, it turns out, equivalent to calling:
//
// id result = [rs objectForColumnName:@"employee_name"];
//
// @param columnName `NSString` value of the name of the column.
//
// @return Either `NSNumber`, `NSString`, `NSData`, or `NSNull`. If the column was `NULL`, this returns `[NSNull null]` object.
// */
//
//- (id _Nullable)objectForKeyedSubscript:(NSString *)columnName;
//
///** Result set object for column.
//
// This method allows the use of the "boxed" syntax supported in Modern Objective-C. For example, by defining this method, the following syntax is now supported:
//
// id result = rs[0];
//
// This simplified syntax is equivalent to calling:
//
// id result = [rs objectForKeyedSubscript:0];
//
// which is, it turns out, equivalent to calling:
//
// id result = [rs objectForColumnName:0];
//
// @param columnIdx Zero-based index for column.
//
// @return Either `NSNumber`, `NSString`, `NSData`, or `NSNull`. If the column was `NULL`, this returns `[NSNull null]` object.
// */
//
//- (id _Nullable)objectAtIndexedSubscript:(int)columnIdx;
//
///** Result set `NSData` value for column.
//
// @param columnName `NSString` value of the name of the column.
//
// @return Data value of the result set's column.
//
// @warning If you are going to use this data after you iterate over the next row, or after you close the
// result set, make sure to make a copy of the data first (or just use `<dataForColumn:>`/`<dataForColumnIndex:>`)
// If you don't, you're going to be in a world of hurt when you try and use the data.
//
// */
//
//- (NSData * _Nullable)dataNoCopyForColumn:(NSString *)columnName NS_RETURNS_NOT_RETAINED;
//
///** Result set `NSData` value for column.
//
// @param columnIdx Zero-based index for column.
//
// @return Data value of the result set's column.
//
// @warning If you are going to use this data after you iterate over the next row, or after you close the
// result set, make sure to make a copy of the data first (or just use `<dataForColumn:>`/`<dataForColumnIndex:>`)
// If you don't, you're going to be in a world of hurt when you try and use the data.
//
// */
//
//- (NSData * _Nullable)dataNoCopyForColumnIndex:(int)columnIdx NS_RETURNS_NOT_RETAINED;
//
///** Is the column `NULL`?
//
// @param columnIdx Zero-based index for column.
//
// @return `YES` if column is `NULL`; `NO` if not `NULL`.
// */
//
//- (BOOL)columnIndexIsNull:(int)columnIdx;
//
///** Is the column `NULL`?
//
// @param columnName `NSString` value of the name of the column.
//
// @return `YES` if column is `NULL`; `NO` if not `NULL`.
// */
//
//- (BOOL)columnIsNull:(NSString*)columnName;
//
///** Returns a dictionary of the row results mapped to case sensitive keys of the column names.
//
// @warning The keys to the dictionary are case sensitive of the column names.
// */

@property (nonatomic, readonly, nullable) NSDictionary *resultDictionary;


@end

NS_ASSUME_NONNULL_END

