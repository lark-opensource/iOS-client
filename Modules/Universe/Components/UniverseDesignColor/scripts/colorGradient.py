import colorTools
import re

# 生成 UDColor+Gradient.swift
def generate_udcolor_gradient_file():
    swift_code = f'''//
//  UDColor+Gradient.swift
//  UniverseDesignColor
//
//  Created by {colorTools.git_username} on {colorTools.formatted_time}.
//  ！！本文件由脚本生成，如需改动，请修改 colorGradient.py 脚本！！
//

import FigmaKit
import UniverseDesignTheme

// swiftlint:disable all
fileprivate extension UDColor {{
    static func fromGradientWithDirection(_ direction: GradientDirection, size: CGSize, colors: [UIColor], type: GradientType = .linear) -> UIColor? {{
        return UIColor.fromGradientWithType(type, direction: direction, frame:  CGRect(origin: .zero, size: size), colors: colors)
    }}
}}

public extension GradientPattern {{

    @available(*, deprecated, message: "不要这么用！GradientPattern 是一个整体，转成 cgColors 会丢失其他信息")
    var cgColors: [CGColor] {{
        colors.map {{ $0.cgColor }}
    }}
}}

extension UDColor {{
'''
    swift_code += generate_color_token_from_tokens()
    swift_code += f'\n}}'
    swift_code += generate_colors_token_from_extension()
    swift_code += f'\n}}'
    swift_code += generate_color_config_from_tokens()
    swift_code += f'\n}}'
    swift_code += generate_color_config_from_extension()
    swift_code += f'\n}}'
    swift_code += f'\n// swiftlint:enable all'
    colorTools.replace_file("UDColor+Gradient.swift", swift_code)


def generate_color_token_from_tokens() -> str:
    # 定义颜色字典并忽略前两行
    code_str = ""
    for row in colorTools.tokens_Sheet.iter_rows(min_row=3):
        if row[1].value and row[4].value and row[5].value:
            token_name = str(row[1].value).replace(" ", "")
            # print(token_name)
            if "gradient" in row[4].value:
                dir1, lights = parse_gradient_colors(str(row[4].value))
                dir2, darks = parse_gradient_colors(str(row[5].value))
                colors = ""
                for i in range(len(lights)):
                    light = str(lights[i]).replace(" ", "")
                    dark = str(darks[i]).replace(" ", "")
                    if light == dark:
                        color = f'{light}'
                    else :
                        color = f'{light} & {dark}'
                    colors += f'{color}, '

                colors = colors[:-2]
                dir = ""
                if "conic-gradient" in str(row[4].value):
                    dir1 = "diagonal45"
                    token = colorTools.process_value(token_name)
                    code_str += f'\n    public static func {token}(ofSize size: CGSize) -> UIColor? {{\n'
                    code_str += f'        return UDColor.fromGradientWithDirection(.{dir1}, size: size, colors: [{colors}], type: .angular)\n'
                    code_str += f'    }}\n'
                else:
                    if dir1.replace(" ", "") == "tobottomright":
                        dir1 = "diagonal135"
                    elif dir1.replace(" ", "") == "90deg":
                        dir1 = "diagonal45"
                    else:
                        dir1 = "leftToRight"
        
                    token = colorTools.process_value(token_name)
                    code_str += f'\n    public static func {token}(ofSize size: CGSize) -> UIColor? {{\n'
                    code_str += f'        return UDColor.fromGradientWithDirection(.{dir1}, size: size, colors: [{colors}])\n'
                    code_str += f'    }}\n'
    return code_str

#def generate_colors() -> str:
#    code_str = "\n\nextension UDColor {\n"
#    for row in colorTools.tokens_Sheet.iter_rows(min_row=3):
#        if row[1].value and row[4].value and row[5].value:
#            token_name = str(row[1].value).replace(" ", "")
#            # print(token_name)
#            if "gradient" in row[4].value:
#                dir1, lights = parse_gradient_colors(str(row[4].value))
#                dir2, darks = parse_gradient_colors(str(row[5].value))
#                colors = ""
#                for i in range(len(lights)):
#                    light = str(lights[i]).replace(" ", "")
#                    dark = str(darks[i]).replace(" ", "")
#                    if light == dark:
#                        color = f'{light}'
#                    else :
#                        color = f'{light} & {dark}'
#                    colors += f'{color}, '
#
#                colors = colors[:-2]
#
#                token = colorTools.process_value(token_name)
#                code_str += f'\n    public static var {token}: [UIColor] {{\n'
#                code_str += f'        return [{colors}]\n'
#                code_str += f'    }}\n'
#    return code_str

def generate_color_config_from_tokens() -> str:
    # 定义颜色字典并忽略前两行
    code_str = "\n\nextension UDColor {\n"
    for row in colorTools.tokens_Sheet.iter_rows(min_row=3):
        if row[1].value and row[4].value and row[5].value:
            token_name = str(row[1].value).replace(" ", "")
            # print(token_name)
            if "gradient" in row[4].value:
                dir1, lights = parse_gradient_colors(str(row[4].value))
                dir2, darks = parse_gradient_colors(str(row[5].value))
                colors = ""
                for i in range(len(lights)):
                    light = str(lights[i]).replace(" ", "")
                    dark = str(darks[i]).replace(" ", "")
                    if light == dark:
                        color = f'{light}'
                    else :
                        color = f'{light} & {dark}'
                    colors += f'{color}, '

                colors = colors[:-2]
                dir = ""
                if "conic-gradient" in str(row[4].value):
                    dir1 = "diagonal45"
                    token = colorTools.process_value(token_name)
                    code_str += f'\n    public static var {token}: GradientPattern {{\n'
                    code_str += f'        return GradientPattern(direction: .{dir1},\n'
                    code_str += f'                               colors: [{colors}],\n'
                    code_str += f'                               type: .angular)\n'
                    code_str += f'    }}\n'
                else:
                    if dir1.replace(" ", "") == "tobottomright":
                        dir1 = "diagonal135"
                    elif dir1.replace(" ", "") == "90deg":
                        dir1 = "diagonal45"
                    else:
                        dir1 = "leftToRight"

                    token = colorTools.process_value(token_name)
                    code_str += f'\n    public static var {token}: GradientPattern {{\n'
                    code_str += f'        return GradientPattern(direction: .{dir1},\n'
                    code_str += f'                               colors: [{colors}])\n'
                    code_str += f'    }}\n'
    return code_str

def generate_color_config_from_extension() -> str:
    # 定义颜色字典并忽略前两行
    code_str = "\n\nextension UDComponentsExtension where BaseType == UIColor {\n"
    for row in colorTools.tokens_Sheet.iter_rows(min_row=3):
        if row[1].value and row[4].value and row[5].value:
            token_name = str(row[1].value).replace(" ", "")
            # print(token_name)
            if "gradient" in row[4].value:
                dir1, lights = parse_gradient_colors(str(row[4].value))
                dir2, darks = parse_gradient_colors(str(row[5].value))
                colors = ""
                for i in range(len(lights)):
                    light = str(lights[i]).replace(" ", "")
                    dark = str(darks[i]).replace(" ", "")
                    if light == dark:
                        color = f'{light}'
                    else :
                        color = f'{light} & {dark}'
                    colors += f'{color}, '

                colors = colors[:-2]
                dir = ""
                if "conic-gradient" in str(row[4].value):
                    dir1 = "diagonal45"
                    token = colorTools.process_value(token_name)
                    code_str += f'\n    public static var {token}: GradientPattern {{\n'
                    code_str += f'        return GradientPattern(direction: .{dir1},\n'
                    code_str += f'                               colors: [{colors}],\n'
                    code_str += f'                               type: .angular)\n'
                    code_str += f'    }}\n'
                else:
                    if dir1.replace(" ", "") == "tobottomright":
                        dir1 = "diagonal135"
                    elif dir1.replace(" ", "") == "90deg":
                        dir1 = "diagonal45"
                    else:
                        dir1 = "leftToRight"

                    token = colorTools.process_value(token_name)
                    code_str += f'\n    public static var {token}: GradientPattern {{\n'
                    code_str += f'        return GradientPattern(direction: .{dir1},\n'
                    code_str += f'                               colors: [{colors}])\n'
                    code_str += f'    }}\n'
    return code_str


def generate_colors_token_from_extension() -> str:
    # 定义颜色字典并忽略前两行
    code_str = "\n\nextension UDComponentsExtension where BaseType == UIColor {\n"
    for row in colorTools.tokens_Sheet.iter_rows(min_row=3):
        if row[1].value and row[4].value and row[5].value:
            token_name = str(row[1].value).replace(" ", "")
            # print(token_name)
            if "gradient" in row[4].value:
                dir1, lights = parse_gradient_colors(str(row[4].value))
                dir2, darks = parse_gradient_colors(str(row[5].value))
                colors = ""
                for i in range(len(lights)):
                    light = str(lights[i]).replace(" ", "")
                    dark = str(darks[i]).replace(" ", "")
                    if light == dark:
                        color = f'{light}'
                    else :
                        color = f'{light} & {dark}'
                    colors += f'{color}, '

                colors = colors[:-2]
                dir = ""

                if "conic-gradient" in str(row[4].value):
                    dir1 = "diagonal45"
                    token = colorTools.process_value(token_name)
                    code_str += f'\n    public static func {token}(ofSize size: CGSize) -> UIColor? {{\n'
                    code_str += f'        return UDColor.fromGradientWithDirection(.{dir1}, size: size, colors: [{colors}], type: .angular)\n'
                    code_str += f'    }}\n'
                else:
                    if dir1.replace(" ", "") == "tobottomright":
                        dir1 = "diagonal135"
                    elif dir1.replace(" ", "") == "90deg":
                        dir1 = "diagonal45"
                    else:
                        dir1 = "leftToRight"
    
                    token = colorTools.process_value(token_name)
                    code_str += f'\n    public static func {token}(ofSize size: CGSize) -> UIColor? {{\n'
                    code_str += f'        return UDColor.fromGradientWithDirection(.{dir1}, size: size, colors: [{colors}])\n'
                    code_str += f'    }}\n'
    return code_str

def parse_gradient_colors(value):
    if "rgba" in value:
        content = value.strip()[len("linear-gradient("):-1]
        parts = content.split(",")
        direction = parts[0].strip()
        colors = []
        matches = re.findall(r'rgba\((.*?),\s*([0-9.]+)\%\)', value)
        for match in matches:
            rgba = match[0]
            alpha = alpha = float(str(match[1]).strip("%")) / 100 
            color = "{}.withAlphaComponent({:.2f})".format(rgba, alpha)
            colors.append(color)
        return direction, colors
    else:
        return extract_colors(value)

def extract_colors(linear_gradient):
    # 提取括号内的元素
    content = linear_gradient.strip()[len("linear-gradient("):-1]
    # 根据逗号分割
    parts = content.split(",")
    # 第一个元素是方向，后面的是颜色
    direction = parts[0].strip()
    colors = [c.strip() for c in parts[1:]]
    # 提取颜色中的变量名
    variable_colors = []
    for color in colors:
        variable_color = re.findall("[A-Za-z]\d+", color)
        if variable_color:
            variable_colors.append(variable_color[0])
    return direction, variable_colors


