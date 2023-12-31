//
//  DynamicResourceAdaptor.swift
//  LarkContact
//
//  Created by shizhengyu on 2021/3/28.
//

import Foundation
import ServerPB
import RustPB

extension Contact_V1_ImageConfiguration {
    static func transform(from: ServerPB_Dynamic_resource_ImageConfiguration) -> Self {
        var configuration = Contact_V1_ImageConfiguration()
        configuration.data = Contact_V1_ImageResourceData.transform(from: from.data)
        configuration.property = Contact_V1_ImageConfigurationProperty.transform(from: from.property)
        configuration.isBackground = from.isBackground
        return configuration
    }
}

extension Contact_V1_ImageResourceData {
    static func transform(from: ServerPB_Dynamic_resource_ImageResourceData) -> Self {
        var resourceData = Contact_V1_ImageResourceData()
        resourceData.type = Contact_V1_ImageResourceType.transform(from: from.type)
        resourceData.rawImage = Contact_V1_RawImageData.transform(from: from.rawImage)
        resourceData.cdnImage = Contact_V1_CdnImageData.transform(from: from.cdnImage)
        resourceData.constantKeyImage = Contact_V1_ConstantKeyImageData.transform(from: from.constantKeyImage)
        resourceData.text = Contact_V1_TextValue.transform(from: from.text)
        resourceData.rawHtml = Contact_V1_TextValue.transform(from: from.rawHtml)
        return resourceData
    }
}

extension Contact_V1_ImageResourceType {
    static func transform(from: ServerPB_Dynamic_resource_ImageResourceType) -> Self {
        switch from {
        case .rawBytes: return .decryptedRawBytes
        case .rawCdnURL: return .decryptedRawCdnURL
        case .constantKey: return .constantKey
        case .rawText: return .rawText
        case .rawHtml: return .rawHtml
        @unknown default: return .unknownType
        }
    }
}

extension Contact_V1_ImageConfigurationProperty {
    static func transform(from: ServerPB_Dynamic_resource_ImageConfigurationProperty) -> Self {
        var property = Contact_V1_ImageConfigurationProperty()
        property.offsetX = from.offsetX
        property.offsetY = from.offsetY
        property.resizeHeight = from.resizeHeight
        property.resizeWidth = from.resizeWidth
        property.alpha = from.alpha
        property.borderRadius = Contact_V1_BorderRadius.transform(from: from.borderRadius)
        return property
    }
}

extension Contact_V1_RawImageData {
    static func transform(from: ServerPB_Dynamic_resource_RawImageData) -> Self {
        var rawImageData = Contact_V1_RawImageData()
        rawImageData.rawData = from.rawData
        return rawImageData
    }
}

extension Contact_V1_CdnImageData {
    static func transform(from: ServerPB_Dynamic_resource_CdnImageData) -> Self {
        var cdnImageData = Contact_V1_CdnImageData()
        cdnImageData.url = from.url
        return cdnImageData
    }
}

extension Contact_V1_TextValue {
    static func transform(from: ServerPB_Dynamic_resource_TextValue) -> Self {
        var textValue = Contact_V1_TextValue()
        textValue.value = from.value
        textValue.fontSize = from.fontSize
        textValue.fontFamily = from.fontFamily
        textValue.color = from.color
        if let align = Contact_V1_TextValue.AlignFormat(rawValue: from.align.rawValue) {
            textValue.align = align
        }
        textValue.lineSpace = from.lineSpace
        textValue.letterSpace = from.letterSpace
        if let textStyle = Contact_V1_TextValue.TextStyle(rawValue: from.textStyle.rawValue) {
            textValue.textStyle = textStyle
        }
        if let overflow = Contact_V1_TextValue.OverflowOption(rawValue: from.overflow.rawValue) {
            textValue.overflow = overflow
        }
        textValue.minFontSize = from.minFontSize
        return textValue
    }
}

extension Contact_V1_BorderRadius {
    static func transform(from: ServerPB_Dynamic_resource_BorderRadius) -> Self {
        var borderRadius = Contact_V1_BorderRadius()
        borderRadius.topLeft = from.topLeft
        borderRadius.topRight = from.topRight
        borderRadius.bottomLeft = from.bottomLeft
        borderRadius.bottomRight = from.bottomRight
        return borderRadius
    }
}

extension Contact_V1_ConstantKeyImageData {
    static func transform(from: ServerPB_Dynamic_resource_ConstantKeyImageData) -> Self {
        var imageData = Contact_V1_ConstantKeyImageData()
        if let type = Contact_V1_ConstantKeyImageData.ConstantKeyImageType(rawValue: from.type.rawValue) {
            imageData.type = type
        }
        imageData.dynamicKey = from.dynamicKey
        imageData.qrCode = from.qrCode
        return imageData
    }
}
