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
    # # 将Swift代码写入文件中
    # with open('UDColor+BaseColor.swift', 'w') as file:
    #     file.write(swift_code)
    # 查找并替换文件
    colorTools.replace_file('UDOCColor+BaseColor.swift', swift_code)


def generate_udcolor_token_file():
    swift_code = f'''//
//  UDOCColor+Token.swift
//  UniverseDesignColor
//
//  Created by {colorTools.git_username} on {colorTools.formatted_time}.
//  ！！本文件由脚本生成，如需改动，请修改 colorBase.py 脚本！！
//

import UIKit
import Foundation

'''
    swift_code += generate_color_token_in_udcolor()
    colorTools.replace_file("UDOCColor+Token.swift", swift_code)

#######################################################

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
                swift_code += f'extension UDOCColor {{\n'
            swift_code += '    /// light: {}, dark: {}\n'.format(hex_light, hex_dark)
            swift_code += f'    @objc public static var {base_token}: UIColor {{ return UDColor.{base_token} }}\n\n'
    if current_letter:
        swift_code += '}\n'
    return swift_code


def generate_color_token_in_udcolor() -> str:
    # 定义颜色字典并忽略前两行
    color_dict = {}
    code_str = '''/// UDOCColor Token
extension UDOCColor {

    /// bgBody, Light: N00, Dark: N00
    @objc public static var bgBase: UIColor { return UDColor.bgBase }
'''
    for row in colorTools.tokens_Sheet.iter_rows(min_row=3):
        if row[1].value and row[4].value and row[5].value:
            token_name = str(row[1].value).replace(" ", "")
            light_color = str(row[4].value).replace(" ", "")
            dark_color = str(row[5].value).replace(" ", "")
            if "gradient" in light_color or "gradient" in dark_color:
                continue
            token = colorTools.process_value(token_name)
            light_color = colorTools.process_value(light_color)
            dark_color = colorTools.process_value(dark_color)
            code_str += f'    /// {token}, Light: {light_color}, Dark: {dark_color}\n'
            code_str += f'    @objc public static var {token}: UIColor {{ return UDColor.{token} }}\n'

    for row in colorTools.biz_token_sheet.iter_rows(min_row=3):
        if row[0].value and row[6].value and row[8].value:
            token_name = str(row[0].value).replace(" ", "")
            biz = str(row[2].value).replace(" ", "")
            light_color = str(row[6].value).replace(" ", "")
            dark_color = str(row[8].value).replace(" ", "")
            if "UD" in biz:
                token = colorTools.process_value(token_name)
                light_color = colorTools.process_value(light_color)
                dark_color = colorTools.process_value(dark_color)

                code_str += f'    /// {token}, Light: {light_color}, Dark: {dark_color}\n'
                code_str += f'    @objc public static var {token}: UIColor {{ return UDColor.{token} }}\n'
    code_str += "}"
    return code_str