import os
import json
import yaml

def print_error(*args):
    print("\n\033[91m[ERROR] ", *args, "\033[00m")


def print_info(*args):
    print("\n\033[92m[INFO] ", *args, "\033[00m")


def print_warning(*args):
    print("\n\033[93m[WARNING] ", *args, "\033[00m")

def exec(cmd: str):
    print("\n\033[96m> {}\033[00m".format(cmd))
    if os.system(cmd) != 0:
        raise Exception("exec cmd failure!")

def load_yaml_file(file, default_value=None):
    result = default_value
    if os.path.exists(file):
        with open(file, "r", encoding="utf-8") as f:
            result = yaml.load(f, Loader=yaml.FullLoader)
    return result

def load_json_file(file, default_value=None):
    result = default_value
    if os.path.exists(file):
        with open(file, "r", encoding="utf-8") as f:
            result = json.load(f)
    return result

def dump_json_file(file, data):
    with open(file, "w") as f:
        json.dump(data, f, indent=4, sort_keys=True, ensure_ascii=False)

def json_pretty(data):
    return json.dumps(data, indent=4, sort_keys=True, ensure_ascii=False)

def generate_virtual_group(components_info_file, module_workspace):
    print_info("generate_virtual_group")
    components_info = load_yaml_file(components_info_file, {})
    default_group = "Modules"
    virtual_group_map = {}
    handle_pods = []
    for module_name, data in components_info.items():
        name = module_name.replace(" ", "_")
        group = data.get("group", default_group)
        for pod_name in data.get("components", {}):
            if pod_name in handle_pods:
                continue
            handle_pods.append(pod_name)
            key = os.path.join("external", pod_name)
            virtual_group_map[key] = os.path.join(group, name, pod_name)

    if os.path.isfile(module_workspace):
        modules = load_json_file(module_workspace, [])
        for info in modules:
            pod_name = info.get("name", "")
            if len(pod_name) == 0 or pod_name in handle_pods:
                continue
            handle_pods.append(pod_name)
            key = os.path.join("external", pod_name)
            virtual_group_map[key] = os.path.join(default_group, pod_name)

    virtual_group_map_file = os.path.join(
        os.path.dirname(components_info_file), "virtual_group_map.json"
    )
    dump_json_file(virtual_group_map_file, virtual_group_map)

def pre_generate_material_hook(obj):
    print("pre_generate_material_hook")
    print(obj)
    workspace_root = os.getcwd()
    module_workspace = os.path.join(workspace_root, "module_workspace.json")
    components_info_file = os.path.join(
        workspace_root, "components_layer_info.yml"
    )
    generate_virtual_group(components_info_file, module_workspace)
    return obj


def post_generate_material_hook(obj):
    print("post_generate_material_hook")


def pre_build_hook(obj):
    print("pre_build_hook")

    # if not bool(os.getenv("BIT_WORKSPACE_DIR")):
    #     heimdallr_plist_path = "external/Heimdallr/Heimdallr/Assets/Core/Heimdallr.plist"
    #     if os.path.exists(heimdallr_plist_path):
    #         exec("git update-index --assume-unchanged {}".format(heimdallr_plist_path))
    #     ttnetversion_plist_path = "external/TTNetworkManager/Pod/Assets/TTNetVersion.plist"
    #     if os.path.exists(ttnetversion_plist_path):
    #         exec("git update-index --assume-unchanged {}".format(ttnetversion_plist_path))


def post_build_hook(obj):
    print("post_build_hook")
