//
//  ICU_MessageFormat.swift
//  LarkLocalizationsDev
//
//  Created by SolaWing on 2022/12/5.
//

import Foundation
// swiftlint:disable identifier_name missing_docs

public struct ICUError: Error {
    public var pattern: String
    public var code: Int32 = 0
    enum Code: Int32 {
        case U_ILLEGAL_ARGUMENT_ERROR = 1
        case U_MEMORY_ALLOCATION_ERROR = 7
    }
    public var isFailure: Bool { code > 0 }
    public var isSuccess: Bool { code <= 0 }
    public var localizedDescription: String { "[ICUError] code: \(code), pattern: `\(pattern)`" }
}
/// ICU format需要指定的类型
public enum ICUFormattable {
    case string(String)
    case double(Double)
    case long(Int32)
    case int64(Int64)
    case date(Date)
    public init(_ value: String) { self = .string(value) }
    public init(_ value: Double) { self = .double(value) }
    public init(_ value: Int32) { self = .long(value) }
    public init(_ value: Int64) { self = .int64(value) }
    public init(_ value: Date) { self = .date(value) }
}
/// 需要保持老接口兼容，所以提供一个统一的转换协议
public protocol ICUValueConvertable {
    func asICUFormattable() -> ICUFormattable
}

extension LanguageManager {
    /// throws ICUError
    /// - Parameters:
    ///    - lang: locale or language for format, default currentLanguage
    public static func format(
        lang: Lang = LanguageManager.currentLanguage,
        pattern: String,
        args: [String: ICUFormattable]
    ) throws -> String {
        // calculate the size
        var stackSize = pattern.utf16.count
        for (k, v) in args {
            stackSize += k.utf16.count
            if case .string(let s) = v {
                stackSize += s.utf16.count
            }
        }
        stackSize *= 2 // * 2 for result buffer
        stackSize = max(512, stackSize)

        return try withUnsafeTemporaryAllocation(of: unichar.self, capacity: stackSize) { (stack) in
            guard let stack = stack.baseAddress
            else { throw ICUError(pattern: pattern, code: ICUError.Code.U_MEMORY_ALLOCATION_ERROR.rawValue) }

            var it = stack
            let endPtr = it + stackSize

            let patternStr = U16_String(string: pattern, buffer: &it)
            let argsPairs = args.map { (key, value) in
                UFormatPair(key: U16_String(string: key, buffer: &it),
                            value: UValue(from: value, buffer: &it))
            }
            let resultBuffer = it
            var status = ICUError(pattern: pattern)
            // call format
            let output = u_formatMessage_kv(
                lang.localeIdentifier, patternStr,
                argsPairs, Int32(argsPairs.count),
                resultBuffer, Int32(endPtr - resultBuffer),
                &status.code)
            defer {
                if let buffer = output.buffer, resultBuffer != buffer {
                    free(UnsafeMutableRawPointer(mutating: buffer))
                }
            }
            guard status.isSuccess, let buffer = output.buffer
            else { throw status }

            return String(utf16CodeUnits: buffer, count: Int(output.len))
        }
    }
}

extension U16_String {
    // NOTE: buffer capacity must not less than string.utf16.count
    // buffer will stop at copy end
    init(string: String, buffer: inout UnsafeMutablePointer<unichar>) {
        let start = buffer
        for i in string.utf16 {
            buffer.pointee = i
            buffer += 1
        }

        self.init(buffer: start, len: Int32(buffer - start))
    }
}

extension UValue {
    init(from: ICUFormattable, buffer: inout UnsafeMutablePointer<unichar>) {
        switch from {
        case .date(let v):
            self = uvalue_from_date(v.timeIntervalSince1970 * 1000)
        case .double(let v):
            self = uvalue_from_double(v)
        case .int64(let v):
            self = uvalue_from_int64(v)
        case .long(let v):
            self = uvalue_from_long(v)
        case .string(let v):
            self = uvalue_from_string(U16_String(string: v, buffer: &buffer))
        }
    }
}

extension ICUFormattable: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { self }
}
extension String: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .string(self) }
}
extension NSString: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .string(self as String) }
}
extension Date: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .date(self) }
}
extension NSDate: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .date(self as Date) }
}
extension NSNumber: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable {
        switch self.objCType.pointee {
        case CChar(truncatingIfNeeded: ("f" as UnicodeScalar).value),
            CChar(truncatingIfNeeded: ("d" as UnicodeScalar).value):
            return .double(self.doubleValue)
        default: return .int64(self.int64Value)
        }
    }
}
extension Float: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .double(Double(self)) }
}
extension Double: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .double(self) }
}

extension Int: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .int64(Int64(self)) }
}
extension Int64: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .int64(self) }
}
extension Int32: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .long(self) }
}
extension Int16: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .long(Int32(self)) }
}
extension Int8: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .long(Int32(self)) }
}
extension UInt: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .int64(Int64(self)) }
}
extension UInt64: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .int64(Int64(self)) }
}
extension UInt32: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .int64(Int64(self)) }
}
extension UInt16: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .long(Int32(self)) }
}
extension UInt8: ICUValueConvertable {
    public func asICUFormattable() -> ICUFormattable { .long(Int32(self)) }
}

#if APP_TEST
// swiftlint:disable all
func testIcuInSwift() {
    let pattern = """
    {norm} {argument, plural, one{C''est # fichier {norm}} other {Ce sont # fichiers}} dans la liste.
    {noun, select, varsh {{count, selectordinal, one{#lā} two{#rā} few{#thā} many{#Thā} other {#vān} } vrh}
        other {{count, selectordinal, one{#lī} two{#rī} few{#thī} many{#Thī} other {#vīn} } {noun}} }
    My OKR progress is {count, number, percent} complete
    Today is {nowTime, date, full}, time is {nowTime, time, full}
    {noun, select, varsh {He} other {She} } likes programming;
    """
    let args: [String: ICUFormattable] = [
        "argument": .int64(10_000),
        "norm": .init("你好"),
        "noun": .init("varsh"),
        "count": .long(22),
        "nowTime": .init(Date(timeIntervalSince1970: 3_600 * 24 * 9))
    ]
    do {
        // 循环一万次，本机模拟器耗时1.15s, 平均每次0.1ms
        let output = try LanguageManager.format(lang: .en_US, pattern: pattern, args: args)
        let expect = """
        你好 Ce sont 10,000 fichiers dans la liste.
        22rā vrh
        My OKR progress is 2,200% complete
        Today is Saturday, January 10, 1970, time is 8:00:00 AM 
        He likes programming;
        """
        print(output)
        if output != expect {
            print("not equal to expect")
        }
    } catch {
        print(error)
    }
    otherTest()
}

private func otherTest() {
    do {
        let output = try LanguageManager.format(lang: .en_US, pattern: "", args: [:])
        if output != "" { print("not equal to expect") }
    } catch {
        print(error)
    }
}
#endif
