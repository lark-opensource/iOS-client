import colorTools
import re

# 生成 UDColor+BaseColor.swift
def generate_udcolor_basecolor_file():
    swift_code = f'''//
//  UDColor+BaseColor.swift
//  UniverseDesignColor
//
//  Created by {colorTools.git_username} on {colorTools.formatted_time}.
//  ！！本文件由脚本生成，如需改动，请修改 colorBase.py 脚本！！
//

import UIKit
import Foundation
import UniverseDesignTheme

'''
    swift_code += generate_base_color_in_udcolor()
    swift_code += generate_base_color_in_udcolor_entension()
    swift_code += generate_get_base_color_by_name_extension()
    # # 将Swift代码写入文件中
    # with open('UDColor+BaseColor.swift', 'w') as file:
    #     file.write(swift_code)
    # 查找并替换文件
    colorTools.replace_file('UDColor+BaseColor.swift', swift_code)


def generate_base_color_in_udcolor() -> str:
    swift_code = ''
    current_letter = ''
    for row in colorTools.keys_sheet.iter_rows():
        base_token = row[0].value.strip() if row[0].value else None
        # 判断A列第一个字母是否为大写字母，如果不是，就跳过该行
        if base_token and not re.match(r'[A-Z]', base_token[0]):
            continue
        hex_light = row[1].value.strip() if row[1].value else None
        hex_dark = row[2].value.strip() if row[2].value else None
        if base_token and hex_light and hex_dark:
            hex_light = hex_light.replace('#', '0x')
            hex_dark = hex_dark.replace('#', '0x')
            color_name = colorTools.color_map.get(base_token[0], 'Red')
            if color_name != current_letter:
                if current_letter:
                    swift_code += '}\n\n'
                current_letter = color_name
                swift_code += f'// MARK: - {current_letter}\n\n'
                swift_code += f'extension UDColor {{\n'
            swift_code += '    /// light: {}, dark: {}\n'.format(hex_light, hex_dark)
            swift_code += f'    public static var {base_token}: UIColor {{ return rgb({hex_light}) & rgb({hex_dark}) }}\n\n'
    if current_letter:
        swift_code += '}\n'
    return swift_code

def generate_base_color_in_udcolor_entension() -> str:
    swift_code = ''
    current_letter = ''
    for row in colorTools.keys_sheet.iter_rows():
        base_token = row[0].value.strip() if row[0].value else None
        # 判断A列第一个字母是否为大写字母，如果不是，就跳过该行
        if base_token and not re.match(r'[A-Z]', base_token[0]):
            continue
        hex_light = row[1].value.strip() if row[1].value else None
        hex_dark = row[2].value.strip() if row[2].value else None
        if base_token and hex_light and hex_dark:
            hex_light = hex_light.replace('#', '0x')
            hex_dark = hex_dark.replace('#', '0x')
            color_name = colorTools.color_map.get(base_token[0], 'Red')
            if color_name != current_letter:
                if current_letter:
                    swift_code += '}\n\n'
                current_letter = color_name
                swift_code += f'// MARK: - {current_letter}\n\n'
                swift_code += f'extension UDComponentsExtension where BaseType == UIColor {{\n'
            swift_code += '    /// light: {}, dark: {}\n'.format(hex_light, hex_dark)
            swift_code += f'    public static var {base_token}: UIColor {{ return UDColor.{base_token} }}\n\n'
    if current_letter:
        swift_code += '}\n'

    return swift_code

def generate_get_base_color_by_name_extension() -> str:
    swift_code = '\n'
    swift_code += f'extension UDColor {{\n\n'
    swift_code += f'    public static func getBaseColorByName(_ baseName: String) -> UIColor? {{\n'
    swift_code += f'        switch baseName {{\n'

    for row in colorTools.keys_sheet.iter_rows():
        base_token = row[0].value.strip() if row[0].value else None
        # 判断A列第一个字母是否为大写字母，如果不是，就跳过该行
        if base_token and not re.match(r'[A-Z]', base_token[0]):
            continue
        hex_light = row[1].value.strip() if row[1].value else None
        hex_dark = row[2].value.strip() if row[2].value else None
        if base_token and hex_light and hex_dark:
            color_name = colorTools.color_map.get(base_token[0], 'Red')
            swift_code += f'        case "{base_token}": return Self.{base_token}\n'
            
    swift_code += '        default: return nil\n'
    swift_code += '        }\n'
    swift_code += '    }\n'
    swift_code += '}\n'
    return swift_code