//
//  UTI.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/23.
//

import Foundation
import MobileCoreServices

/// http://seriot.ch/resources/utis_graph/utis_graph.pdf
public struct UTI {
}

extension UTI {
    public static let Item: String = kUTTypeItem as String
    public static let Content: String = kUTTypeContent as String
    public static let CompositeContent: String = kUTTypeCompositeContent as String
    public static let Message: String = kUTTypeMessage as String
    public static let Contact: String = kUTTypeContact as String
    public static let Archive: String = kUTTypeArchive as String
    public static let DiskImage: String = kUTTypeDiskImage as String

    public static let Data: String = kUTTypeData as String
    public static let Directory: String = kUTTypeDirectory as String
    public static let Resolvable: String = kUTTypeResolvable as String
    public static let SymLink: String = kUTTypeSymLink as String
    public static let Executable: String = kUTTypeExecutable as String
    public static let MountPoint: String = kUTTypeMountPoint as String
    public static let AliasFile: String = kUTTypeAliasFile as String
    public static let AliasRecord: String = kUTTypeAliasRecord as String
    public static let URLBookmarkData: String = kUTTypeURLBookmarkData as String

    public static let URL: String = kUTTypeURL as String
    public static let FileURL: String = kUTTypeFileURL as String

    public static let Text: String = kUTTypeText as String
    public static let PlainText: String = kUTTypePlainText as String
    public static let UTF8PlainText: String = kUTTypeUTF8PlainText as String
    public static let UTF16ExternalPlainText: String = kUTTypeUTF16ExternalPlainText as String
    public static let UTF16PlainText: String = kUTTypeUTF16PlainText as String
    public static let DelimitedText: String = kUTTypeDelimitedText as String
    public static let CommaSeparatedText: String = kUTTypeCommaSeparatedText as String
    public static let TabSeparatedText: String = kUTTypeTabSeparatedText as String
    public static let UTF8TabSeparatedText: String = kUTTypeUTF8TabSeparatedText as String
    public static let RTF: String = kUTTypeRTF as String

    public static let HTML: String = kUTTypeHTML as String
    public static let XML: String = kUTTypeXML as String

    public static let SourceCode: String = kUTTypeSourceCode as String
    public static let AssemblyLanguageSource: String = kUTTypeAssemblyLanguageSource as String
    public static let CSource: String = kUTTypeCSource as String
    public static let ObjectiveCSource: String = kUTTypeObjectiveCSource as String
    public static let SwiftSource: String = kUTTypeSwiftSource as String
    public static let CPlusPlusSource: String = kUTTypeCPlusPlusSource as String
    public static let ObjectiveCPlusPlusSource: String = kUTTypeObjectiveCPlusPlusSource as String
    public static let CHeader: String = kUTTypeCHeader as String
    public static let CPlusPlusHeader: String = kUTTypeCPlusPlusHeader as String
    public static let JavaSource: String = kUTTypeJavaSource as String

    public static let Script: String = kUTTypeScript as String
    public static let AppleScript: String = kUTTypeAppleScript as String
    public static let OSAScript: String = kUTTypeOSAScript as String
    public static let OSAScriptBundle: String = kUTTypeOSAScriptBundle as String
    public static let JavaScript: String = kUTTypeJavaScript as String
    public static let ShellScript: String = kUTTypeShellScript as String
    public static let PerlScript: String = kUTTypePerlScript as String
    public static let PythonScript: String = kUTTypePythonScript as String
    public static let RubyScript: String = kUTTypeRubyScript as String
    public static let PHPScript: String = kUTTypePHPScript as String

    public static let JSON: String = kUTTypeJSON as String
    public static let PropertyList: String = kUTTypePropertyList as String
    public static let XMLPropertyList: String = kUTTypeXMLPropertyList as String
    public static let BinaryPropertyList: String = kUTTypeBinaryPropertyList as String

    public static let PDF: String = kUTTypePDF as String
    public static let RTFD: String = kUTTypeRTFD as String
    public static let FlatRTFD: String = kUTTypeFlatRTFD as String
    public static let TXNTextAndMultimediaData: String = kUTTypeTXNTextAndMultimediaData as String
    public static let WebArchive: String = kUTTypeWebArchive as String

    public static let Image: String = kUTTypeImage as String
    public static let JPEG: String = kUTTypeJPEG as String
    public static let JPEG2000: String = kUTTypeJPEG2000 as String
    public static let TIFF: String = kUTTypeTIFF as String
    public static let PICT: String = kUTTypePICT as String
    public static let GIF: String = kUTTypeGIF as String
    public static let PNG: String = kUTTypePNG as String
    public static let QuickTimeImage: String = kUTTypeQuickTimeImage as String
    public static let AppleICNS: String = kUTTypeAppleICNS as String
    public static let BMP: String = kUTTypeBMP as String
    public static let ICO: String = kUTTypeICO as String
    public static let RawImage: String = kUTTypeRawImage as String
    public static let ScalableVectorGraphics: String = kUTTypeScalableVectorGraphics as String
    public static let LivePhoto: String = kUTTypeLivePhoto as String

    public static let AudiovisualContent: String = kUTTypeAudiovisualContent as String
    public static let Movie: String = kUTTypeMovie as String
    public static let Video: String = kUTTypeVideo as String
    public static let Audio: String = kUTTypeAudio as String
    public static let QuickTimeMovie: String = kUTTypeQuickTimeMovie as String
    public static let MPEG: String = kUTTypeMPEG as String
    public static let MPEG2Video: String = kUTTypeMPEG2Video as String
    public static let MPEG2TransportStream: String = kUTTypeMPEG2TransportStream as String
    public static let MP3: String = kUTTypeMP3 as String
    public static let MPEG4: String = kUTTypeMPEG4 as String
    public static let MPEG4Audio: String = kUTTypeMPEG4Audio as String
    public static let AppleProtectedMPEG4Audio: String = kUTTypeAppleProtectedMPEG4Audio as String
    public static let AppleProtectedMPEG4Video: String = kUTTypeAppleProtectedMPEG4Video as String
    public static let AVIMovie: String = kUTTypeAVIMovie as String
    public static let AudioInterchangeFileFormat: String = kUTTypeAudioInterchangeFileFormat as String
    public static let WaveformAudio: String = kUTTypeWaveformAudio as String
    public static let MIDIAudio: String = kUTTypeMIDIAudio as String

    public static let Playlist: String = kUTTypePlaylist as String
    public static let M3UPlaylist: String = kUTTypeM3UPlaylist as String

    public static let Folder: String = kUTTypeFolder as String
    public static let Volume: String = kUTTypeVolume as String
    public static let Package: String = kUTTypePackage as String
    public static let Bundle: String = kUTTypeBundle as String
    public static let PluginBundle: String = kUTTypePluginBundle as String
    public static let SpotlightImporter: String = kUTTypeSpotlightImporter as String
    public static let QuickLookGenerator: String = kUTTypeQuickLookGenerator as String
    public static let XPCService: String = kUTTypeXPCService as String
    public static let Framework: String = kUTTypeFramework as String

    public static let Application: String = kUTTypeApplication as String
    public static let ApplicationBundle: String = kUTTypeApplicationBundle as String
    public static let ApplicationFile: String = kUTTypeApplicationFile as String
    public static let UnixExecutable: String = kUTTypeUnixExecutable as String

    public static let WindowsExecutable: String = kUTTypeWindowsExecutable as String
    public static let JavaClass: String = kUTTypeJavaClass as String
    public static let JavaArchive: String = kUTTypeJavaArchive as String

    public static let SystemPreferencesPane: String = kUTTypeSystemPreferencesPane as String

    public static let GNUZipArchive: String = kUTTypeGNUZipArchive as String
    public static let Bzip2Archive: String = kUTTypeBzip2Archive as String
    public static let ZipArchive: String = kUTTypeZipArchive as String

    public static let Spreadsheet: String = kUTTypeSpreadsheet as String
    public static let Presentation: String = kUTTypePresentation as String
    public static let Database: String = kUTTypeDatabase as String

    public static let VCard: String = kUTTypeVCard as String
    public static let ToDoItem: String = kUTTypeToDoItem as String
    public static let CalendarEvent: String = kUTTypeCalendarEvent as String
    public static let EmailMessage: String = kUTTypeEmailMessage as String

    public static let InternetLocation: String = kUTTypeInternetLocation as String

    public static let InkText: String = kUTTypeInkText as String
    public static let Font: String = kUTTypeFont as String
    public static let Bookmark: String = kUTTypeBookmark as String
    public static let UT3DContent: String = kUTType3DContent as String
    public static let PKCS12: String = kUTTypePKCS12 as String
    public static let X509Certificate: String = kUTTypeX509Certificate as String
    public static let ElectronicPublication: String = kUTTypeElectronicPublication as String
    public static let Log: String = kUTTypeLog as String
}
