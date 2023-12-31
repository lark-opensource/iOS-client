//
//  MailCheckContentManager.swift
//  MailSDK
//
//  Created by Bytedance on 2022/11/8.
//

#if IS_BYTEST_PACKAGE
import Foundation

let bytestCheckContentScript = """
<script>
var _resultBefore;
var _resultAfter;

window.checkContentBefore = function checkContentBeforeScale() {
    // scale
    // scale_num, scale_cost_time
    const scaleResult = checkScrollableContent();
    const fontResult = checkFontSize();
    _resultBefore = {
        "font": fontResult,
        "scale": scaleResult
    }
}

window.checkContentAfter = function checkContentAfterScale() {
    const scaleResult = checkScrollableContent();
    const fontResult = checkFontSize();
    _resultAfter = {
        "font": fontResult,
        "scale": scaleResult
    }

    //track
    console.log(`checkContentAfter before ${JSON.stringify(_resultBefore)}`);
    console.log(`checkContentAfter after ${JSON.stringify(_resultAfter)}`);
    if (_resultBefore) {
        // 加工打点数据
        // scale
        let params = {};
        const scaleResultBefore = _resultBefore.scale;
        const scaleResultAfter = _resultAfter.scale;
        params.scale_num_before = scaleResultBefore.scaleNum;
        params.scale_num_after = scaleResultAfter.scaleNum;
        params.scale_num_delta = scaleResultAfter.scaleNum - scaleResultBefore.scaleNum;
        params.scale_cost_time = scaleResultBefore.scaleCostTime + scaleResultAfter.scaleCostTime;
        if (params.scale_num_before != 0) {
            params.scale_ratio = Number(((scaleResultBefore.scaleNum - scaleResultAfter.scaleNum) / scaleResultBefore.scaleNum).toFixed(2));
        }

        // Font
        const fontResultBefore = _resultBefore.font;
        const fontResultAfter = _resultAfter.font;
        params.font_total_str_length = fontResultBefore.totalStrLength;
        params.font_small_ratio_before = Number(fontResultBefore.smallStrRatio.toFixed(2));
        params.font_small_ratio_after = Number(fontResultAfter.smallStrRatio.toFixed(2));
        params.font_small_ratio_delta = Number((fontResultAfter.smallStrRatio - fontResultBefore.smallStrRatio).toFixed(2));
        params.font_average_size_before = Number(fontResultBefore.averageFontSize.toFixed(2));
        params.font_average_size_after = Number(fontResultAfter.averageFontSize.toFixed(2));
        params.font_average_size_delta = Number((fontResultAfter.averageFontSize - fontResultBefore.averageFontSize).toFixed(2));
        params.font_average_size_delta_abs = Math.abs(params.font_average_size_delta);
        params.font_cost_time = fontResultBefore.fontCostTime + fontResultAfter.fontCostTime;
        params.threadId = window.t_id;
        return params;
    }
}

function checkScrollableContent() {
    const startTime = Date.now();
    const allMessageContents = document.querySelectorAll('.message-content');
    let scrollableNode = [];
    allMessageContents.forEach(content => {
        const allNodes = content.querySelectorAll('*');
        allNodes.forEach(n => {
            if (n.scrollWidth > n.clientWidth) {
                // scrollable
                let outerContainer = n;
                let par = n;
                while(par) {
                    console.log('checking');
                    par = par.parentNode;
                    if (par && par.scrollWidth == n.scrollWidth && par.clientWidth == n.clientWidth) {
                        outerContainer = par
                    }
                }
                let inqueue = false;
                scrollableNode.forEach(scr => {
                    if (scr === outerContainer) {
                        //已经存在，不打点
                        inqueue = true;
                    }
                });
                if (!inqueue) {
                    scrollableNode.push(outerContainer);
                }
            }
        })
    });
    return {
        "scaleNum": scrollableNode.length,
        "scaleCostTime": Date.now() - startTime
    }
}

function checkFontSize() {
    const startTime = Date.now();
    // Get all text node
    const allMessageContents = document.querySelectorAll('.message-content');
    let allTextNodes = [];
    allMessageContents.forEach(content => {
        const textNodes = textNodesUnder(content);
        textNodes.forEach(textEl => {
            let par = textEl;
            if (par.textContent.trim().length <= 0) {
                // 忽略单纯空格、换行字符串
                return;
            }

            while (par.parentNode != undefined && par.nodeType != 1) {
                par = par.parentNode;
            }
            let duplicate = false;
            for (let i = 0; i < allTextNodes.length; i++) {
                if (allTextNodes[i] === par) {
                    duplicate = true;
                    break;
                }
            }
            if (!duplicate) {
                allTextNodes.push(par);
            } else {
                console.log(`Text node parent duplicate for ${par.textContent}`);
            }
        });
    });

    // Get all computedFontSize
    console.log(allTextNodes);
    const defaultSize = 14;
    let results = {};
    // 字符总数、字体大小和对应的字符数、小于16px的字符数
    let fontMap = new Map();
    let smallFontMap = new Map();
    let transformedFontMap = new Map();
    let totalStrLength = 0;
    let smallStrLength = 0;
    let totalStrFontSize = 0;
    allTextNodes.forEach(n => {
        const s = getComputedStyle(n);
        const strLength = n.textContent.length;
        totalStrLength += strLength;
        let size = parseFloat(s.fontSize);

        // 计算Scale值
        const scaleX = Math.round(n.getBoundingClientRect().width) / n.offsetWidth;
        const scaleY = Math.round(n.getBoundingClientRect().height) / n.offsetHeight;
        const scale = Math.min(scaleX, scaleY);
        size = size * scale;


        if (!isNaN(size)) {
            const count = fontMap.get(size) ? fontMap.get(size) + strLength : strLength;
            totalStrFontSize += (strLength * size);
            fontMap.set(size, count)
            if (size < defaultSize) {
                smallFontMap[size] = smallFontMap[size] ? smallFontMap[size] + 1 : 1;
                smallStrLength += n.textContent.length;
            }
        }
    });
    console.log(totalStrLength);

    const smallStrRatio = smallStrLength / totalStrLength;
    
    const cost = Date.now() - startTime;
    return {
        "totalStrLength": totalStrLength,
        "smallStrRatio": smallStrRatio,
        "averageFontSize": totalStrFontSize / totalStrLength,
        "fontCostTime": cost,
    }
}

function textNodesUnder(el) {
    var n, a = [], walk = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, null, false);
    while (n = walk.nextNode()) a.push(n);
    return a;
}
</script>
"""
#endif
