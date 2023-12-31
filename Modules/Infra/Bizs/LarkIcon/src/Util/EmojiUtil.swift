//
//  EmojiUtil.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/13.
//

import Foundation

public class EmojiUtil {
    
    //判断是否有效
    /// - Parameter v: The Unicode code point to use for the scalar. `v` must be
    ///   a valid Unicode scalar value, in the ranges `0...0xD7FF` or
    ///   `0xE000...0x10FFFF`. In case of an invalid unicode scalar value, nil is
    ///   returned.
    static func emojiKeyIsVaild(code: Int32) -> Bool {
        if code >= 0 && code <= 0xD7FF {
            return true
        }
        if code >= 0xE000 && code < 0x10FFFF {
            return true
        }
        return false
    }
    
    //文本转换成emoji
    public static func scannerStringChangeToEmoji(key: String?) -> String? {
        guard let key = key else {
            LarkIconLogger.logger.warn("scannerStringChangeToEmoji , key is nil")
            return nil
        }
        
        //通过-拆分，进行转换
        var hasError = false
        let emojiArr = key.split(separator: "-").map { str in
            
            //转换Emoji
            let scanner = Scanner(string: String(str))
            
            var result: Int32 = 0
            let success = scanner.scanHexInt32(&result)
            if success == false || !emojiKeyIsVaild(code: result) {
                hasError = true
                return ""
            }
            //后台返回的key如果乱码，result数字过大，使用Unicode.Scalar会carsh，所以这里走了下判断保护emojiKeyIsVaild
            guard let unicode = Unicode.Scalar(Int(result)) else {
                LarkIconLogger.logger.warn("scannerStringChangeToEmoji nil, key： \(key)，str：\(str)")
                hasError = true
                return ""
            }
            let chat = Character(unicode)
            return "\(chat)"
            
        }
        
        //解析过程发生了错误，就显示默认的，避免乱码的情况
        guard !hasError else {
            return ""
        }
        
        //拼接成字符串
        let emoji = emojiArr.joined()
        
        return emoji
    }
}
