//
//  FileFormat.swift
//  LarkFoundation
//
//  Created by ChalrieSu on 08/03/2018.
//  Copyright © 2018 com.bytedance.lark. All rights reserved.
//

import Foundation

public enum FileFormat: Equatable {
    case unknown, txt, md, json, html, pdf, rtf,
    image(ImageFormat), video(VideoFormat),
    audio(AudioFormat), office(OfficeFormat), appleOffice(AppleOfficeFormat)
}

public enum ImageFormat: String {
    case png, jpeg, gif, flif, webp, bmp, tif, svg
}

public enum AudioFormat: String {
    case mp3, m4a, opus, ogg, flac, amr, wav, aac, au
}

public enum VideoFormat: String {
    case avi, mpeg4, mov, wmv, mpg, flv
}

public enum OfficeFormat: String {
    case doc, ppt, xls, officeX, office2007
}

public enum AppleOfficeFormat: String {
    case key, numbers, pages
}

public struct DataStruct {
    let data: [UInt8?]
    let offset: Int
    let format: FileFormat

    init(data: [UInt8?], offset: Int = 0, format: FileFormat) {
        self.data = data
        self.offset = offset
        self.format = format
    }
}

// http://www.garykessler.net/library/file_sigs.html
struct HeaderData {
    // swiftlint:disable identifier_name
    // disable-lint: magic number

    // image
    static var PNG = DataStruct(data: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], format: .image(.png))
    static var JPEG = DataStruct(data: [0xFF, 0xD8, 0xFF], format: .image(.jpeg))
    static var GIF = DataStruct(data: [0x47, 0x49, 0x46], format: .image(.gif))
    static var FLIF = DataStruct(data: [0x46, 0x4C, 0x49, 0x46], format: .image(.flif))
    static var WEBP = DataStruct(data: [0x57, 0x45, 0x42, 0x50], format: .image(.webp))
    static var BMP = DataStruct(data: [0x42, 0x4D], format: .image(.bmp))
    static var TIF_1 = DataStruct(data: [0x49, 0x20, 0x49], format: .image(.tif))
    static var TIF_2 = DataStruct(data: [0x49, 0x49, 0x2A, 0x00], format: .image(.tif))
    static var TIF_3 = DataStruct(data: [0x4D, 0x4D, 0x00, 0x2A], format: .image(.tif))
    static var TIF_4 = DataStruct(data: [0x4D, 0x4D, 0x00, 0x2B], format: .image(.tif))

    // audio
    static var MP3_1 = DataStruct(data: [0x49, 0x44, 0x33], format: .audio(.mp3))
    static var MP3_2 = DataStruct(data: [0xFF, 0xFB], format: .audio(.mp3))
    // 这个必须在前面，video的MPEG_4前面几位相同
    static var M4A = DataStruct(data: [0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41], offset: 4, format: .audio(.m4a))
    static var OPUS = DataStruct(data: [0x4F, 0x70, 0x75, 0x73, 0x48, 0x65, 0x61, 0x64], offset: 28, format: .audio(.opus))
    static var OGG = DataStruct(data: [0x4F, 0x67, 0x67, 0x53], format: .audio(.ogg))
    static var FLAC = DataStruct(data: [0x66, 0x4C, 0x61, 0x43], format: .audio(.flac))
    static var WAV = DataStruct(data: [0x52, 0x49, 0x46, 0x46, nil, nil, nil, nil, 0x57, 0x41, 0x56, 0x45], offset: 0, format: .audio(.wav))
    static var AMR = DataStruct(data: [0x23, 0x21, 0x41, 0x4D, 0x52, 0x0A], format: .audio(.amr))
    static var AAC_1 = DataStruct(data: [0xFF, 0xF1], format: .audio(.aac))
    static var AAC_2 = DataStruct(data: [0xFF, 0xF9], format: .audio(.aac))
    static var AU = DataStruct(data: [0x2E, 0x73, 0x6E, 0x64], format: .audio(.au))

    // video
    static var AVI: DataStruct {
        let data: [UInt8?] = [0x52, 0x49, 0x46, 0x46, nil, nil, nil, nil, 0x41, 0x56, 0x49, 0x20, 0x4C, 0x49, 0x53, 0x54]
        return DataStruct(data: data, format: .video(.avi))
    }
    static var MPEG_4_1 = DataStruct(data: [0x66, 0x74, 0x79, 0x70, 0x33, 0x67, 0x70], offset: 4, format: .video(.mpeg4))
    static var MPEG_4_2 = DataStruct(data: [0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x56, 0x20], offset: 4, format: .video(.mpeg4))
    static var MPEG_4_3 = DataStruct(data: [0x66, 0x74, 0x79, 0x70, 0x4D, 0x53, 0x4E, 0x56], offset: 4, format: .video(.mpeg4))
    static var MPEG_4_4 = DataStruct(data: [0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6F, 0x6D], offset: 4, format: .video(.mpeg4))
    static var MPEG_4_5 = DataStruct(data: [0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32], offset: 4, format: .video(.mpeg4))
    static var MOV = DataStruct(data: [0x66, 0x74, 0x79, 0x70, 0x71, 0x74, 0x20, 0x20], offset: 4, format: .video(.mov))
    static var WMV = DataStruct(data: [0x30, 0x26, 0xB2, 0x75, 0x8E, 0x66, 0xCF, 0x11, 0xA6, 0xD9], format: .video(.wmv))
    static var MPG = DataStruct(data: [0x0, 0x0, 0x1, 0xBA], format: .video(.mpg))
    static var FLV = DataStruct(data: [0x46, 0x4C, 0x56, 0x01], format: .video(.flv))
    // office
    static var DOC_1 = DataStruct(data: [0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, 0x0], format: .office(.doc))
    static var DOC_2 = DataStruct(data: [0x0D, 0x44, 0x4F, 0x43], format: .office(.doc))
    static var DOC_3 = DataStruct(data: [0xDB, 0xA5, 0x2D, 0x0], format: .office(.doc))
    static var DOC_4 = DataStruct(data: [0xEC, 0xA5, 0xC1, 0x0], offset: 512, format: .office(.doc))
    static var PPT_1 = DataStruct(data: [0xA0, 0x46, 0x1D, 0xF0], offset: 512, format: .office(.ppt))
    static var PPT_2 = DataStruct(data: [0xFD, 0xFF, 0xFF, 0xFF, nil, nil, 0x0, 0x0], offset: 512, format: .office(.ppt))
    static var PPT_3 = DataStruct(data: [0x0, 0x6E, 0x1E, 0xF0], offset: 512, format: .office(.ppt))
    static var PPT_4 = DataStruct(data: [0x0F, 0x0, 0xE8, 0x03], offset: 512, format: .office(.ppt))
    static var XLS_1 = DataStruct(data: [0xFD, 0xFF, 0xFF, 0xFF, nil, 0x02], offset: 512, format: .office(.xls))
    static var XLS_2 = DataStruct(data: [0xFD, 0xFF, 0xFF, 0xFF, 0x20], offset: 512, format: .office(.xls))
    static var XLS_3 = DataStruct(data: [0x09, 0x08, 0x10, 0x0, 0x0, 0x06, 0x05], offset: 512, format: .office(.xls))
    // other
    static var PDF = DataStruct(data: [0x25, 0x50, 0x44, 0x46], format: .pdf)
    // apple
    static var RTF = DataStruct(data: [0x7B, 0x5C, 0x72, 0x74, 0x66, 0x31], format: .pdf)

    // enable-lint: magic number
    // swiftlint:enable identifier_name

    static var typeDatas = [
        PNG, JPEG, GIF, FLIF, WEBP, BMP, TIF_1, TIF_2, TIF_3, TIF_4,
        MP3_1, MP3_2, M4A, OPUS, OGG, FLAC, WAV, AMR, AAC_1, AAC_2, AU,
        AVI, MPEG_4_1, MPEG_4_2, MPEG_4_3, MPEG_4_4, MPEG_4_5, MOV, WMV, MPG, FLV,
        DOC_1, DOC_2, DOC_3, DOC_4, PPT_1, PPT_2, PPT_3, PPT_4, XLS_1, XLS_2, XLS_3,
        PDF,
        RTF
    ]
}
