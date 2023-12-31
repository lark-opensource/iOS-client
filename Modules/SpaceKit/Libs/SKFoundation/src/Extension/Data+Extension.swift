//
//  Data+Extension.swift
//  SpaceKit
//
//  Created by maxiao on 2018/11/12.
//

import Foundation
import LarkStorage
import LarkSetting

extension Data {
    
    //统一存储改造bridge
    public func unifyWrite(to mediaFileCachePath: SKFilePath, imageName: String) throws -> URL {
        DocsLogger.info("[Uni_storage] data write using LarkStorage API")
        let skFilePath = mediaFileCachePath.appendingRelativePath(imageName)
        try self.write(to: skFilePath)
        return skFilePath.pathURL
    }
    
    public static func unifyContentsOf(url: URL) throws -> Data  {
        DocsLogger.info("[Uni_storage] data read using LarkStorage API")
        let pathAbs = AbsPath(url.absoluteString)
        return try Data.read(from: pathAbs)
    }

    public var toISO88591String: String? {
        let estr = "iso-8859-1"
        let cfe = CFStringConvertIANACharSetNameToEncoding(estr as CFString)
        let se = CFStringConvertEncodingToNSStringEncoding(cfe)
        let encoding = String.Encoding(rawValue: se)
        let ISO88591String = String(data: self, encoding: encoding)

        return ISO88591String
    }

    public var toBase64Stirng: String? {
        return self.base64EncodedString()
    }

    static func filterBOMChar(_ data: inout Data) {
        DocsLogger.info("[BOM] filterBOMChar begin")
        defer {
            DocsLogger.info("[BOM] filterBOMChar end, byte.count:\(data.count)")
        }
        /*
            UTF-8 的编码规则 http://www.ruanyifeng.com/blog/2007/10/ascii_unicode_and_utf-8.html
            1）对于单字节的符号，字节的第一位设为0，后面7位为这个符号的 Unicode 码。因此对于英语字母，UTF-8 编码和 ASCII 码是相同的。
            2）对于n字节的符号（n > 1），第一个字节的前n位都设为1，第n + 1位设为0，后面字节的前两位一律设为10。剩下的没有提及的二进制位，全部为这个符号的 Unicode 码。
            下表总结了编码规则，字母x表示可用编码的位。
            Unicode符号范围     |        UTF-8编码方式
            (十六进制)        |              （二进制）
            ----------------------+---------------------------------------------
            0000 0000-0000 007F | 0xxxxxxx
            0000 0080-0000 07FF | 110xxxxx 10xxxxxx
            0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx
            0001 0000-0010 FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        */

        var replaceIndexs = [Int]()
        data.withUnsafeMutableBytes { bytes  in

            var foundStartByte = false
            var bLen = 0 //字节长度
            var index = 0
            let maxIndex = bytes.count - 3

            while index <= maxIndex {
                let current = bytes[index]
                if (current & 0xFC) == 0xFC {
                    //当前以0x11111100开头，标记6字节编码开始，后面需紧跟5个0x10开头字节
                    foundStartByte = true
                    bLen = 6
                } else if (current & 0xF8) == 0xF8 {
                    //当前以0x11111000开头，标记5字节编码开始，后面需紧跟4个0x10开头字节
                    foundStartByte = true
                    bLen = 5
                } else if (current & 0xF0) == 0xF0 {
                    //当前以0x11110000开头，标记4字节编码开始，后面需紧跟3个0x10开头字节
                    foundStartByte = true
                    bLen = 4
                } else if (current & 0xE0) == 0xE0 {
                    //当前以0x11100000开头，标记3字节编码开始，后面需紧跟2个0x10开头字节
                    foundStartByte = true
                    bLen = 3
                } else if (current & 0xC0) == 0xC0 {
                    //当前以0x11000000开头，标记2字节编码开始，后面需紧跟1个0x10开头字节
                    foundStartByte = true
                    bLen = 2
                } else if (current & 0x80) == 0x80 {
                    //当前以0x1000000开头
                    //发现0x80~0xC0之间字节，不是utf8编码,放弃替换
                    foundStartByte = false
                    replaceIndexs.removeAll()
                    spaceAssertionFailure("[BOM]非utf8编码")
                    break
                } else {
                    //当前字节小于128，标准ASCII码范围
                    foundStartByte = true
                    bLen = 1
                }

                if foundStartByte {
                    if bLen == 3, index <= maxIndex,
                       bytes[index] == 0xEF && bytes[index + 1] == 0xBB && bytes[index + 2] == 0xBF {
                        replaceIndexs.append(index) //记录要替换的index
                    }
                    index += bLen //跳到下一个字符
                }
            }

            for index in replaceIndexs where index <= maxIndex {
                //替换为零宽空格 U+200
                bytes[index] = 0xE2
                bytes[index + 1] = 0x80
                bytes[index + 2] = 0x8B
            }
        }

        if !replaceIndexs.isEmpty {
            DocsLogger.info("[BOM]replace bom char count:\(replaceIndexs.count)")
        }
    }
}

extension NSPointerArray {
    public func addObject(_ object: AnyObject?) {
        guard let strongObject = object else { return }

        let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
        addPointer(pointer)
    }
}
