import React, { memo, useContext, useState, useEffect } from "react";
import { TabBar, Button } from "@arco-design/mobile-react";
import { Radio } from "@arco-design/web-react";
import NavBarComponent from "@/components/NavBarComponent";
import SearchConfigCard from "@/components/SearchConfigCard";
import UIConfigCard from "@/components/UIConfigCard";
import RecommendConfigCard from "@/components/RecommendConfigCard";
import { ConfigContext } from "@/Context";
import { getEntities } from "@/utils/utils";
import { openPicker, close } from "@/utils/appBridge";
const RadioGroup = Radio.Group;

const MainPage = memo((props) => {
  const context = useContext(ConfigContext);
  const { state, dispatch } = context;
  const [entities, setEntities] = useState([]);
  const [style, setStyle] = useState("picker");

  useEffect(() => {
    let entities = getEntities(state?.config?.searchConfig?.entities ?? []);
    setEntities(entities);
    console.log("state:", state);
  }, [state]);
  const handleOpenPicker = () => {
    let config = state.config;
    config.style = style;
    console.log("open picker:", state.config);
    const string = JSON.stringify(state.config);
    openPicker(string);
  };

  const handleClose = () => {
    close();
  };
  // UI
  const BottomBar = () => {
    return (
      <TabBar className="bg-white pb-4">
        <div className="flex flex-col items-center">
          <div className="flex flex-row space-x-4 justify-between px-4">
            <Button
              style={{ width: "120px" }}
              type="ghost"
              onClick={handleClose}
            >
              关闭
            </Button>
            <Button
              style={{ width: "120px" }}
              type="primary"
              long={true}
              onClick={handleOpenPicker}
            >
              打开Picker
            </Button>
          </div>
          <div className="text-blue-500/10">version: 2023111001</div>
        </div>
      </TabBar>
    );
  };

  return (
    <div className="">
      <NavBarComponent title="Picker配置" />
      {/* Body */}
      <div className="flex flex-col items-center justify-between pb-10">
        <div className="pt-2">
          <RadioGroup
            type="button"
            name="lang"
            size="large"
            defaultValue={style}
            onChange={(value) => setStyle(value)}
            style={{ marginRight: 20, marginBottom: 20 }}
          >
            <Radio value="picker">Picker样式</Radio>
            <Radio value="search">搜索样式</Radio>
          </RadioGroup>
        </div>
        {/* Config */}
        <div className="flex flex-col space-y-2 pb-2 items-center">
          <SearchConfigCard entities={entities} />
          <UIConfigCard />
          <RecommendConfigCard />
        </div>
        {/* Button */}
        <BottomBar />
      </div>
    </div>
  );
});

export default MainPage;
