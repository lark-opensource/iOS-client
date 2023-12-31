//
//  MobileCodeProvider.swift
//  LarkLogin
//
//  Created by 姚启灏 on 2019/1/13.
//

import Foundation
import LarkReleaseConfig
import LarkLocalizations
import LarkStorage

public struct MobileCode {
    public let key: String
    public let name: String
    public let code: String
    public let index: String
    public let pinyin: String?
    public let romaWord: String?
    public let format: [Int]

    public init(key: String, name: String, code: String, index: String, pinyin: String?, romaWord: String, format: [Int]) {
        self.key = key
        self.name = name
        self.code = code
        self.index = index
        self.pinyin = pinyin
        self.romaWord = romaWord
        self.format = format
    }
}

/// 多国语言适配：原始翻译文档和资源文件的生成 https://bytedance.feishu.cn/docs/doccnjoB6WKXcer4wZ8VbeXPgTc#TuKAsx
public final class MobileCodeProvider {
    /// Lark 差异数据（翻译上Lark和飞书是不同的）
    static let larkDataKey = "lark_data"
    /// Lark 差异数据中 的顺序号
    static let orderIndex = "order_index"
    /// 数据内容
    static let dataKey = "data"
    /// 国家地区名
    static let nameKey = "name"
    /// 国家地区手机码
    static let codeKey = "code"
    /// 索引
    static let indexKey = "head_index"
    /// 拼音全拼
    static let pinyinKey = "full_pinyin"
    /// 号码分段形式
    static let patternKey = "pattern"
    /// 日语 罗马音
    static let romaWordKey = "roma_word"
    /// 国家地区码顺序列表
    static let normalList = "normal_list"
    /// 置顶显示国家地区列表
    static let topList = "top_list"
    static let fileExtension = "json"
    static let mobileCodeDirectory = "MobileCode"

    private let mobileCodeLocale: Lang
    private var mobileCodes: [MobileCode] = []
    private var normalList: [String] = []
    private var topList: [String] = []
    private var indexList: [String] = []

    private lazy var phoneNumberFormatPattern: NSRegularExpression = {
        // swiftlint:disable:next force_try
        return try! NSRegularExpression(pattern: "\\(\\\\d\\{(\\d+)\\}\\)", options: [.caseInsensitive])
    }()

    /// 初始化
    /// - Parameters:
    ///   - mobileCodeLocale: 读取哪种语言的数据
    ///   - topCountryList: 显示在顶部的国家或地区
    ///   - blackCountryList: 不需要显示的国家或地区
    public init(mobileCodeLocale: Lang, topCountryList: [String], blackCountryList: [String]) {
        self.mobileCodeLocale = mobileCodeLocale
        self.readData(
            locale: mobileCodeLocale,
            topCountryList: topCountryList,
            allowCountryList: [],
            blockCountryList: blackCountryList
        )
    }

    /// 初始化
    /// - Parameters:
    ///   - mobileCodeLocale: 读取哪种语言的数据
    ///   - topCountryList: 显示在顶部的国家或地区
    ///   - allowCountryList: 允许显示的所有国家，不为空时，仅展示 allowCountryList 内的国家代码
    ///   - blockCountryList: 不需要显示的国家或地区
    public init(mobileCodeLocale: Lang, topCountryList: [String], allowCountryList: [String], blockCountryList: [String]) {
        self.mobileCodeLocale = mobileCodeLocale
        self.readData(
            locale: mobileCodeLocale,
            topCountryList: topCountryList,
            allowCountryList: allowCountryList,
            blockCountryList: blockCountryList
        )
    }

    // 返回Top列表第一个MobileCode
    public func getFirstTopMobileCode() -> MobileCode? {
        return searchCountry(countryKey: mobileCodeLocale.regionCode ?? "") ?? getMobileCodes().first
    }

    // 返回默认排序的MobileCode
    public func getMobileCodes() -> [MobileCode] {
        return mobileCodes
    }

    // 返回TopList的key
    public func getTopList() -> [String] {
        return topList
    }

    // 返回NormalList的key
    public func getNormalList() -> [String] {
        return normalList
    }

    // 返回IndexList的key
    public func getIndexList() -> [String] {
        return indexList
    }

    // 通过拼音、名字或者号码搜索，模糊匹配
    public func searcMobileCode(searchText: String) -> [MobileCode] {
        let text = searchText.lowercased()

        return self.getMobileCodes().filter { string in
            return string.code.lowercased().contains(text) ||
                string.name.lowercased().contains(text) ||
                (string.pinyin?.lowercased().contains(text) ?? false) ||
                (string.romaWord?.lowercased().contains(text) ?? false)
        }
    }

    // 通过电话号码搜索国家，完全匹配
    public func searchCountry(searchCode: String) -> MobileCode? {
        let mobileCodes = self.getMobileCodes()
        var topMobileCode: MobileCode?
        self.getTopList().forEach { (key) in
            mobileCodes.forEach({ (mobileCode) in
                if mobileCode.key == key,
                    mobileCode.code == searchCode {
                    topMobileCode = mobileCode
                }
            })
        }
        if let topMobileCode = topMobileCode {
            return topMobileCode
        } else {
            return mobileCodes.first(where: { $0.code == searchCode })
        }
    }

    // 通过key搜索mobileCode
    public func searchCountry(countryKey: String) -> MobileCode? {
        return self.getMobileCodes().first(where: { $0.key == countryKey })
    }

    private func parseFormat(_ pattern: String?) -> [Int] {
        guard let pattern = pattern else {
            return []
        }
        /// 兼容1位数字分段的情况，如：塞舌尔 (\\d)(\\d{3})(\\d{3})
        let normalizedPattern = pattern.replacingOccurrences(of: "(\\d)", with: "(\\d{1})")

        var results: [Int] = []
        let patterns = phoneNumberFormatPattern.matches(in: normalizedPattern, options: [], range: NSRange(location: 0, length: normalizedPattern.count))
        for subPattern in patterns {
            let range = subPattern.range(at: 1)
            let startIdx = normalizedPattern.index(normalizedPattern.startIndex, offsetBy: range.lowerBound)
            let endIdx = normalizedPattern.index(normalizedPattern.startIndex, offsetBy: range.lowerBound)
            if let i = Int(normalizedPattern[startIdx...endIdx]) {
                results.append(i)
            }
        }
        return results
    }
}

extension MobileCodeProvider {

    private func resourceFilePathOfLocale() -> AbsPath? {
        if !Lang.isUnzip() {
            /// 判断压缩包未解压进行解压
            Lang.unZip()
        }
        let path = Lang.filePath(lang: mobileCodeLocale)
        if path.exists {
            return path.asAbsPath()
        }
        return BundleConfig.LarkUIKitBundle.absPath(
            forResource: Lang.en_US.mobileCodeFileName,
            ofType: MobileCodeProvider.fileExtension,
            inDirectory: MobileCodeProvider.mobileCodeDirectory
        )
    }

    // 如果白名单不为空，以白名单为准
    private func readData(locale: Lang, topCountryList: [String], allowCountryList: [String], blockCountryList: [String]) {
        var normalList: [String] = []
        var topList: [String] = []
        var mobileCodes: [MobileCode] = []
        var indexList: [String] = []

        // 读取对应语言Json
        if let path = resourceFilePathOfLocale(),
           let data = try? Data.read(from: path),
           let jsonData = (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)) as? [String: Any] {
            // 语言顺序码
            normalList = jsonData[MobileCodeProvider.normalList] as? [String] ?? []

            if topCountryList.isEmpty {
                topList = jsonData[MobileCodeProvider.topList] as? [String] ?? []
            } else {
                topList = topCountryList
            }

            if !allowCountryList.isEmpty {
                topList = topList.filter { allowCountryList.contains($0) }
            } else {
                topList = topList.filter { !blockCountryList.contains($0) }
            }

            var larkData: [String: Any]?
            if ReleaseConfig.isLark {
                // 如果是Lark 读取 Lark 差异数据
                larkData = jsonData[MobileCodeProvider.larkDataKey] as? [String: Any]
                if let data = larkData {
                    normalList = adjustLarkNormalList(normalList, data: data)
                }
            }

            if !allowCountryList.isEmpty {
                normalList = normalList.filter { allowCountryList.contains($0) }
            } else {
                normalList = normalList.filter { !blockCountryList.contains($0) }
            }

            if let _mobileCodes = jsonData[MobileCodeProvider.dataKey] as? [String: Any] {

                normalList.forEach { (key) in
                    var tmpMobileCode: [String: Any]?
                    if let code = larkData?[key] as? [String: Any] {
                        tmpMobileCode = code
                    } else {
                        tmpMobileCode = _mobileCodes[key] as? [String: Any]
                    }
                    if let mobileCode = tmpMobileCode {
                        let index = (mobileCode[MobileCodeProvider.indexKey] as? String)?.uppercased() ?? ""

                        let _mobileCode = MobileCode(key: key,
                                name: mobileCode[MobileCodeProvider.nameKey] as? String ?? "",
                                code: mobileCode[MobileCodeProvider.codeKey] as? String ?? "",
                                index: index,
                                pinyin: mobileCode[MobileCodeProvider.pinyinKey] as? String,
                                romaWord: mobileCode[MobileCodeProvider.romaWordKey] as? String ?? "",
                                format: parseFormat(mobileCode[MobileCodeProvider.patternKey] as? String))
                        if !indexList.contains(index) && !index.isEmpty {
                            indexList.append(index)
                        }
                        mobileCodes.append(_mobileCode)
                    }
                }
            }
        }

        self.mobileCodes = mobileCodes
        self.normalList = normalList
        self.topList = topList
        self.indexList = indexList
    }

    /// Lark 中部分国家地区码顺序和飞书不同这里做个调整
    func adjustLarkNormalList(_ normalList: [String], data: [String: Any]) -> [String] {
        // 删除 Lark 数据中包含的地区码，准备重新按照新的顺序插入
        var normalList = normalList.filter({ !data.keys.contains($0) })

        var orderdLangCode: [(String, Int)] = []
        // 解析数据 按照从小到大的顺序生成数组(从小到大排保证插入的时候的index是准确的)
        data.forEach { (info) in
            guard let value = info.value as? [String: Any],
                     let index = value[Self.orderIndex] as? Int else {
                assertionFailure("lark data must have order_index")
                return
            }
            orderdLangCode.append((info.key, index))
        }
        orderdLangCode.sort(by: { $0.1 < $1.1 })
        // 按照顺序插入normalList
        orderdLangCode.forEach { (langCode, index) in
            guard index <= normalList.count else {
                assertionFailure("index should not greater than count")
                return
            }
            normalList.insert(langCode, at: index)
        }
        return normalList
    }
}

extension Lang {

    fileprivate var mobileCodeFileName: String {
        return "mobile_code_\(languageIdentifier)"
    }

    fileprivate static func filePath(lang: Lang) -> IsoPath {
        /// eg. Documents/.../MobileCode/mobile_code_en-US.json
        return unZipMobileCodeFilePath()
            + MobileCodeProvider.mobileCodeDirectory
            + "\(lang.mobileCodeFileName).\(MobileCodeProvider.fileExtension)"
    }

    fileprivate static func isUnzip() -> Bool {
        /// 判断下是否已经解压
        return self.filePath(lang: Lang.en_US).exists
    }

    fileprivate static func unZip() {
        let directory = MobileCodeProvider.mobileCodeDirectory
        let bundle = BundleConfig.LarkUIKitBundle
        guard let zipFilePath = bundle.path(forResource: "MobileCode", ofType: "zip", inDirectory: directory) else {
            return
        }
        // try unzip file
        do {
            let unzipTargetPath = unZipMobileCodeFilePath()
            try unzipTargetPath.unzipFile(fromPath: zipFilePath.asAbsPath())
        } catch {
            return
        }
    }

    fileprivate static func unZipMobileCodeFilePath() -> IsoPath {
        let path = IsoPath.in(space: .global, domain: Domain.biz.core.child("MobileCode")).build(.document)
        try? path.createDirectoryIfNeeded()
        return path
    }
}
