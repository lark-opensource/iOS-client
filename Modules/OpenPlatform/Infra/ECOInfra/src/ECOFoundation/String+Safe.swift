//
//  String+Safe.swift
//  ECOInfra
//
//  Created by Meng on 2021/2/26.
//

import Foundation
import LarkSetting

extension NSString {
    /// 字符串掩码脱敏
    /// 将任意字符串转换为掩码脱敏，尽可能不泄漏信息的前提下，暴露信息用于问题排查。
    /// 例如：
    /// "123456789" => "12*****89"
    /// "MONITOR_WEB_ID" => "MO*****_***_ID"
    /// "_ga" => "_**"
    /// "_hjid" => "_h**d"
    /// "rutland-session" => "ru*****-*****on"
    ///
    /// - Parameters:
    ///   - padding: 前后保留字符长度, 如果长度较短时优先使用掩码策略
    ///   - pad: 掩码
    ///   - except: 忽略字符
    /// - Returns: 替换掩码后的字符串
    @objc(maskWithPadding:pad:except:)
    public func maskForObjc(padding: Int, pad: unichar, except: String) -> String {
        let origin = self as String
        let characterPad = UnicodeScalar(pad).map({ Character($0) }) ?? String.defaultMaskPad
        return origin.mask(padding: padding, pad: characterPad, except: except.map({ $0 }))
    }

    @objc(maskWithExcept:)
    public func maskForObjc(except: String) -> String {
        let origin = self as String
        return origin.mask(except: except.map({ $0 }))
    }

    @objc(reuseCacheMaskWithExcept:)
    public func reuseCacheMaskForObjc(except: String) -> String {
        let origin = self as String
        return origin.reuseCacheMask(except: except.map({ $0 }))
    }

    @objc(mask)
    public func maskForObjc() -> String {
        let origin = self as String
        return origin.mask()
    }

    @objc(reuseCacheMask)
    public func reuseCacheMaskForObjc() -> String {
        let origin = self as String
        return origin.reuseCacheMask()
    }
}

extension String {
    public static let defaultMaskPadding: Int = 2
    public static let defaultMaskPad: Character = "*"
    public static let defaultMaskExcept: [Character] = []

    public func reuseCacheMask(
        padding: Int = String.defaultMaskPadding,
        pad: Character = String.defaultMaskPad,
        except: [Character] = String.defaultMaskExcept
    ) -> String {
        let key = StringSafeCacheUtils.reuseCacheKey(maskStr: self, padding: padding, pad: pad, except: except)
        if let cache = StringSafeCacheUtils.getCache(key) {
            return cache
        }
        let result = mask(padding: padding, pad: pad, except: except)
        StringSafeCacheUtils.setCache(key, result)
        return result
    }

    /// 字符串掩码脱敏
    /// 将任意字符串转换为掩码脱敏，尽可能不泄漏信息的前提下，暴露信息用于问题排查。
    /// 例如：
    /// "123456789" => "12*****89"
    /// "MONITOR_WEB_ID" => "MO*****_***_ID"
    /// "_ga" => "_**"
    /// "_hjid" => "_h**d"
    /// "rutland-session" => "ru*****-*****on"
    ///
    /// - Parameters:
    ///   - padding: 前后保留字符长度, 如果长度较短时优先使用掩码策略
    ///   - pad: 掩码
    ///   - except: 忽略字符
    /// - Returns: 替换掩码后的字符串
    public func mask(
        padding: Int = String.defaultMaskPadding,
        pad: Character = String.defaultMaskPad,
        except: [Character] = String.defaultMaskExcept
    ) -> String {
        // 参数异常，全部使用掩码返回
        if padding < 0 {
            return String(repeating: pad, count: count)
        }
        let realCount = count
        // 不需要处理的字符数量
        let exceptCount = filter({ except.contains($0) }).count
        // 需要处理的字符数量
        let includeCount = realCount - exceptCount

        // 前后保留字符数量大于可处理字符数，可处理字符全部掩码返回
        if padding * 2 > includeCount {
            return String(map({ except.contains($0) ? $0 : pad }))
        }

        let minMaskLength = Int(ceil(Double(includeCount) / 2.0)) /* 暴露信息不能多于一半 */
        var fixPrefixLength = padding /* 极端情况调整后的prefixLength */
        var fixSuffixLength = padding /* 极端情况调整后的suffixfixLength */
        if includeCount < padding * 2 + minMaskLength {
            let fixSize = Double(padding * 2 + minMaskLength - includeCount)
            fixPrefixLength = max(padding - Int(floor(fixSize / 2.0)), 0)
            fixSuffixLength = max(padding - Int(ceil(fixSize / 2.0)), 0)
        }

        let iterator = enumerated()
        var prefixOriginCount = 0 /* 前缀保留字符数量 */
        var currentExceptCount = 0 /* 当前扫描不需要处理字符数量 */
        var currentMaskCount = 0 /* 当前替换为掩码的数量 */
        return String(iterator.map { (offset, element) -> Character in
            // 不需要处理的字符直接返回
            if except.contains(element) {
                currentExceptCount += 1
                return element
            }

            let suffixCount = realCount - offset /* 剩余未处理字符（包含当前字符） */
            let suffixExceptCount = exceptCount - currentExceptCount /* 剩余未处理字符中的except字符 */
            let suffixIncludeCount = suffixCount - suffixExceptCount /* 剩余未处理字符中的include字符 */

            // 优先保证前缀数量，但剩余未处理字符不能少于 minMaskLength
            if suffixIncludeCount > minMaskLength && prefixOriginCount < fixPrefixLength {
                prefixOriginCount += 1
                return element /* 明文前缀 */
            }

            // 满足mask字符数量 且 剩余数量 <= 明文后缀
            if currentMaskCount >= minMaskLength && suffixIncludeCount <= fixSuffixLength {
                return element /* 明文后缀 */
            }

            currentMaskCount += 1
            return pad /* 掩码 */
        })
    }
}

fileprivate final class StringSafeCacheUtils {
    @RealTimeFeatureGating(key: "openplatform.api.disable_string_mask_prompt") // Global
    private static var disableMaskCache: Bool

    private static let maskPromptCache: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 200
        cache.totalCostLimit = 2 * 1024 * 1024
        return cache
    }()

    fileprivate static func reuseCacheKey(
        maskStr: String,
        padding: Int,
        pad: Character,
        except: [Character]
    ) -> String {
        return "\(maskStr)-\(padding)-\(pad)-\(except)"
    }

    fileprivate static func getCache(_ key: String) -> String? {
        if disableMaskCache {
            return nil
        }
        return maskPromptCache.object(forKey: key as NSString) as? String
    }

    fileprivate static func setCache(_ key: String, _ value: String) {
        if disableMaskCache {
            return
        }
        maskPromptCache.setObject(value as NSString, forKey: key as NSString)
    }
}
