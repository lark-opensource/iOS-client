//
//  MailSignaturePreviewScript.swift
//  MailSDK
//
//  Created by majx on 2020/1/21.
//

import Foundation

struct MailSignaturePreviewScript {
    static let darkModeJS = """
    var baseBackgroundColor;
    var baseFrontColor;
    var darken;
    var root = document.querySelector(':root');

    function initDarkSDK() {
        darken = new Darken({
           darkFrontColor: 'rgb(235, 235, 235)',
           darkBackgroundColor: 'rgb(26, 26, 26)',
           lightFrontColor: 'rgb(31, 35, 41)',
           lightBackgroundColor: 'rgb(255, 255, 255)',
        });
        root.classList.add('light');
    }
    
    function makeDarkMode() {
        if (root.classList.contains('dark')) {
            return;
        }
        root.classList.remove('light');
        root.classList.add('dark');
        document.body.style.color = 'rgb(215, 218, 224)';
        document.body.style.backgroundColor = 'rgb(41, 41, 41)';
        var lightItem = document.body.children;
        for(let i = 0;i<lightItem.length;i++) {
            const { costTime: darkenCostTime } = darken.darken({
                html: lightItem[i],
                selectorPrependInStyle: '.dark',
            });
        }
    }
    
    function makeLightMode() {
        if (root.classList.contains('light')) {
            return;
        }
        root.classList.remove('dark');
        root.classList.add('light');
        document.body.style.color = 'rgb(31, 35, 41)';
        document.body.style.backgroundColor = 'white';
        var darkItem = document.body.children;
        for(let i = 0;i<darkItem.length;i++) {
            const {costTime: lightenCostTime } = darken.lighten({
                html: darkItem[i],
            });
        }
    }
    
    """
    
    static let closeEditable = """
        var editableDivs = document.querySelectorAll("div[contenteditable='true']");
        if (editableDivs !== undefined) {
            for(let i = 0; i < editableDivs.length; i++) {
                let div = editableDivs[i];
                div.setAttribute('contenteditable', 'false');
            }
        }
    """

    static let newSigCloseEditableAndAddClick = """
        document.addEventListener('click', function(){
            console.log('hehe');
            window.webkit.messageHandlers.invoke.postMessage({'method':'clickSignature','args': {}});
        })
        var editableDivs = document.querySelectorAll("div[contenteditable='true']");
        if (editableDivs !== undefined) {
            for(let i = 0; i < editableDivs.length; i++) {
                let div = editableDivs[i];
                div.setAttribute('contenteditable', 'false');
            }
        }
    """

    static let closeEditableAndAddClick = """
        var editableDivs = document.querySelectorAll("div[contenteditable='true']");
        if (editableDivs !== undefined) {
            for(let i = 0; i < editableDivs.length; i++) {
                let div = editableDivs[i];
                div.setAttribute('contenteditable', 'false');
                div.onclick = function() {
                    window.webkit.messageHandlers.invoke.postMessage({'method':'clickSignature','args': {}});
                }
            }
        }
    """
    static let mobileScalable = """
        var meta = document.createElement('meta');
        meta.setAttribute('name', 'viewport');
        meta.setAttribute('content', 'width=device-width, initial-scale=1, user-scalable=no');
        var head = document.getElementsByTagName('head');
        if (head !== undefined && head.length > 0) {
            head[0].appendChild(meta);
        }
    """

    static let getContentHeight = """
        var height = document.body.scrollHeight;
        height;
    """
    static let interpolateSignatureTemplate = """
        function replaceJsonDic(valueJson) {
            var nodelist = document.body.querySelectorAll(`[data-variable-meta-props]`);
            for (i=0;i<nodelist.length;i++) {
                var node = nodelist[i];
                var node_str = node.getAttribute('data-variable-meta-props');
                try {
                    var json = JSON.parse(node_str);
                    var dataJson = JSON.parse(valueJson);
                    var key = json.id;
                    var value = dataJson[key] || '';
                    if (json.type == 'text') {
                        node.innerText = value;
                    }
                } catch (error) {
                    try {
                        var json = JSON.parse(node_str);
                        if (json.type == 'text') {
                            node.innerText = '';
                        }
                    } catch (error) {
                        // nothing
                    }
                }
            }
        }

        """
    static let interpolateLarkCircularFont = """
        function initFontStyle(fontNormalBase64, fontBoldBase64) {
            const fontStyle = document.createElement('style');
            fontStyle.textContent = `
            @font-face {
              font-family: Lark Circular;
              font-weight: normal;
              src: local('Lark Circular'),
                   url('data:@file/octet-stream;base64,${fontNormalBase64}');
            }
            @font-face {
              font-family: Lark Circular;
              font-weight: bold;
              src: local('Lark Circular'),
                   url('data:@file/octet-stream;base64,${fontBoldBase64}');
            }
            `;
            document.head.appendChild(fontStyle);
            document.body.style.fontFamily = \"Lark Circular, -apple-system\"
        }
    """
}
