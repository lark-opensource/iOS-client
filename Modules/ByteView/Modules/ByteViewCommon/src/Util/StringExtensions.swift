//
//  StringExtensions.swift
//  ByteViewCommon
//
//  Created by kiri on 2022/8/24.
//

import Foundation

extension String: VCExtensionCompatible {}
public extension VCExtension where BaseType == String {
    func boundingWidth(height: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        boundingSize(with: CGSize(width: .greatestFiniteMagnitude, height: height), attributes: attributes).width
    }

    func boundingHeight(width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        boundingSize(with: CGSize(width: width, height: .greatestFiniteMagnitude), attributes: attributes).height
    }

    func boundingWidth(height: CGFloat, font: UIFont) -> CGFloat {
        boundingSize(with: CGSize(width: .greatestFiniteMagnitude, height: height), attributes: [.font: font]).width
    }

    func boundingHeight(width: CGFloat, font: UIFont) -> CGFloat {
        boundingSize(with: CGSize(width: width, height: .greatestFiniteMagnitude), attributes: [.font: font]).height
    }

    func boundingWidth(height: CGFloat, config: VCFontConfig) -> CGFloat {
        boundingSize(with: CGSize(width: .greatestFiniteMagnitude, height: height), attributes: config.toAttributes()).width
    }

    func boundingHeight(width: CGFloat, config: VCFontConfig) -> CGFloat {
        boundingSize(with: CGSize(width: width, height: .greatestFiniteMagnitude), attributes: config.toAttributes()).height
    }

    func boundingSize(with size: CGSize, config: VCFontConfig) -> CGSize {
        boundingSize(with: size, attributes: config.toAttributes())
    }

    func boundingSize(with size: CGSize, attributes: [NSAttributedString.Key: Any]) -> CGSize {
        NSString(string: base).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size
    }
}
