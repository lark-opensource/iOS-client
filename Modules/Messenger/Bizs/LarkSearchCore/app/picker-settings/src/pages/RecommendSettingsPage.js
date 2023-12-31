import React, { memo, useState, useContext, useEffect } from "react";
import { Divider, Radio } from "@arco-design/web-react";
import { List, Avatar } from "@arco-design/web-react";
import { IconCheckCircle, IconArrowRight } from "@arco-design/web-react/icon";
import { Tabs } from "@arco-design/mobile-react";
import { ConfigContext } from "../Context";
import NavBarComponent from "@/components/NavBarComponent";
import ContactSettings from "@/components/recommend/ContactSettings";

const RecommendSettingsPage = memo(() => {
  const theRef = React.useRef();
  const context = useContext(ConfigContext);
  const { state, dispatch } = context;
  const type = state?.config?.recommendType;
  const index = type === "contact" ? 0 : type === "search" ? 1 : 2;

  const tabData = [
    { title: "联系人列表" },
    { title: "大搜空搜" },
    { title: "无" },
  ];

  useEffect(() => {
    console.log("Recommend settings", type);
  }, []);

  return (
    <div className="recommend_settings">
      <NavBarComponent title="推荐列表" hasBack={true} />
      <Tabs
        ref={theRef}
        tabs={tabData}
        type="line-divide"
        defaultActiveTab={index}
        tabBarHasDivider={false}
        onAfterChange={(tab, index) => {
          console.log("[tabs]", tab, index);
          dispatch({ event: "changeRecommendType", payload: { index: index } });
        }}
        translateZ={false}
      >
        <ContactSettings />
        <div className="demo-tab-content">使用空搜配置</div>
        <div className="demo-tab-content">无推荐列表</div>
      </Tabs>
      <div className="flex flex-col"></div>
      <div className="main flex flex-col items-center pt-2"></div>
    </div>
  );
});

export default RecommendSettingsPage;
