const fs = require('fs');
const path = require('path');

function matchImageAssets(content) {
    const res = [];
    let matchArr;

    const imageRegex = /UIImage\(named: ?"(.*?)"\)/g;
    while((matchArr = imageRegex.exec(content)) != null) {
        res.push(matchArr[1]);
    }

    const literalRegex = /#imageLiteral\(resourceName: ?"(.*?)"\)/g;
    while((matchArr = literalRegex.exec(content)) != null) {
        res.push(matchArr[1]);
    }

    return res;
}

function matchAbnormalImageAssets(content) {
    const res = [];
    let matchArr;

    const imageRegex = /(UIImage\(named: ?[^")]+\))/g;
    while((matchArr = imageRegex.exec(content)) != null) {
        res.push(matchArr[1]);
    }

    return res
}

function matchAndReplaceImageAssets(content, path) {
    const imageRegex = /UIImage\(named: ?"(.*?)"\)/g;
    const newContent = content.replace(imageRegex, "#imageLiteral(resourceName: \"$1\")");

    fs.writeFileSync(path, newContent);

    return [];
}

function matchAndReplaceColors(content, path) {
    const colorRGBA = /UIColor\(red: ?(\d+(\.\d+)?( ?\/ ?\d+(\.\d+)?)?), green: ?(\d+(\.\d+)?( ?\/ ?\d+(\.\d+)?)?), blue: ?(\d+(\.\d+)?( ?\/ ?\d+(\.\d+)?)?), alpha: ?(\d+(\.\d+)?( ?\/ ?\d+(\.\d+)?)?)\)/g;
    const colorRGB = /UIColor\(red: ?(\d+(\.\d+)?( ?\/ ?\d+(\.\d+)?)?), green: ?(\d+(\.\d+)?( ?\/ ?\d+(\.\d+)?)?), blue: ?(\d+(\.\d+)?( ?\/ ?\d+(\.\d+)?)?)\)/g;
    const colorWA = /UIColor\(white: ?(\d+(\.\d+)?( ?\/ ?\d+(\.\d+)?)?), alpha: ?(\d+(\.\d+)?( ?\/ ?\d+(\.\d+)?)?)\)/g;
    const newContent = content
        .replace(colorRGBA, '#colorLiteral(red: $1, green: $5, blue: $9, alpha: $13)')
        .replace(colorRGB, '#colorLiteral(red: $1, green: $5, blue: $9, alpha: 1)')
        .replace(colorWA, '#colorLiteral(red: $1, green: $1, blue: $1, alpha: $5)')

    fs.writeFileSync(path, newContent);

    return [];
}

function deleteFolderRecursive(srcPath) {
    if (fs.existsSync(srcPath) ) {
        fs.readdirSync(srcPath).forEach((file) => {
            const curPath = path.join(srcPath, file);
            if (fs.lstatSync(curPath).isDirectory()) {
                deleteFolderRecursive(curPath);
            } else {
                fs.unlinkSync(curPath);
            }
        });
        fs.rmdirSync(srcPath);
    }
};

function getImageAssets(srcpath, exclude) {
    let assets = [];

    const dirs = fs.readdirSync(srcpath)
        .filter(file => !file.startsWith('.'))
        .filter(file => fs.lstatSync(path.join(srcpath, file)).isDirectory());

    const assetNames = dirs
        .filter(dir => dir.endsWith('.imageset'))
        .map(dir => {
            return {
                name: dir.substr(0, dir.lastIndexOf('.')),
                path: path.join(srcpath, dir)
            }
        });
    assets = assets.concat(assetNames);
    dirs.filter(dir => !dir.endsWith('.imageset')).forEach(dir => {
        assets = assets.concat(getImageAssets(path.join(srcpath, dir), exclude));
    });

    assets = assets.filter((asset) => {
        return !asset.path.match(exclude)
    });

    return assets;
}

function getMatchedImageAssets(srcpath, matchAssets) {
    let usedAssets = [];

    const files = fs.readdirSync(srcpath).filter(file => !file.startsWith('.'));
    files.filter(file => fs.lstatSync(path.join(srcpath, file)).isFile() && file.endsWith('.swift'))
        .forEach(file => {
            const curPath = path.join(srcpath, file);
            const content = fs.readFileSync(curPath).toString();
            usedAssets = usedAssets.concat(matchAssets(content, curPath).map(asset => {
                return {
                    name: asset,
                    path: curPath
                };
            }));
        });

    files.filter(file => !file.startsWith('.'))
        .filter(file => fs.lstatSync(path.join(srcpath, file)).isDirectory())
        .forEach(dir => {
            usedAssets = usedAssets.concat(getMatchedImageAssets(path.join(srcpath, dir), matchAssets));
        });

    return usedAssets;
}

function getAbnormalImageAssets(srcpath) {
    return getMatchedImageAssets(srcpath, matchAbnormalImageAssets);
}

function getUnusedImageAssets(srcpath, exclude) {
    const assets = getImageAssets(srcpath, exclude);
    const usedAssets = getMatchedImageAssets(srcpath, matchImageAssets);

    const assetsMap = {};
    assets.forEach(asset => assetsMap[asset.name] = asset);

    const usedAssetsMap = {};
    usedAssets.forEach(asset => usedAssetsMap[asset.name] = asset);

    const unusedAssets = [];
    for (name in assetsMap) {
        if (!usedAssetsMap[name]) {
            unusedAssets.push(assetsMap[name]);
        }
    }

    for (name in usedAssetsMap) {
        if (!assetsMap[name]) {
            console.log("!!Warning cannot find asset [" + name + "]")
        }
    }

    return unusedAssets;
}

function replaceImageSets(srcPath) {
    getMatchedImageAssets(srcPath, matchAndReplaceImageAssets);
}

function replaceColor(srcPath) {
    getMatchedImageAssets(srcPath, matchAndReplaceColors)
}

// const content = fs.readFileSync("./Lark/Modules/Audio/View/AudioPlayStatusView.swift").toString();
// console.log(matchImageAssets(content));

// console.log(getImageAssets('./Lark'));

// console.log(getMatchedImageAssets('./Lark'));

// console.log(getUnusedImageAssets('./Lark').map(asset => asset.name));

// console.log(getAbnormalImageAssets('./Lark'));


function main() {
    const func = process.argv[2];
    const srcPath = process.argv[3];
    let exclude = process.argv[4];
    if (func == "replace") {
        replaceImageSets(srcPath);
    } else if (func == "remove") {
        exclude = RegExp(exclude);
        const assets = getUnusedImageAssets(srcPath, exclude);
        if (assets.length <= 0) {
            console.log("no unused imagesets");
        } else {
            assets.forEach(asset => {
                if (asset.name.endsWith("_en") || asset.name.endsWith("_zh")) {
                    console.log("i18n imageset {" + asset.name + "}");
                    return
                }
                console.log("remove imageset {" + asset.name + "}");
                deleteFolderRecursive(asset.path);
            });
        }
    } else if (func == "replace-color") {
        replaceColor(srcPath);
    } else {
        console.log("not supported command");
    }
}

main();
