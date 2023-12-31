import React, { useReducer, useContext } from "react";
import { HashRouter, Route, Routes } from "react-router-dom";
import { configReducer } from "./reducers/configReducer";
import { ConfigContext } from "./Context";
import MainPage from "./pages/MainPage";
import SearchConfigListPage from "@/pages/SearchConfigListPage";
import UIConfigSettingsPage from "@/pages/UIConfigSettingsPage";
import RecommendSettingsPage from "@/pages/RecommendSettingsPage";
import BusinessConfigPage from "@/pages/BusinessConfigPage";
import Demo from "@/pages/Demo";
import "@arco-design/mobile-react/dist/style.css";
import "@arco-design/web-react/dist/css/arco.css";
import configString from "./config/config.json";

import setRootPixel from "@arco-design/mobile-react/tools/flexible";
setRootPixel();

const localConfig = JSON.parse(configString);

function App(props) {
  const { initialState } = props;

  const [state, dispatch] = useReducer(configReducer, {
    config: initialState || localConfig,
  });
  return (
    <HashRouter>
      <ConfigContext.Provider value={{ state, dispatch }}>
        <Routes>
          <Route path="/" element={<MainPage />}></Route>
          <Route
            path="/search-config"
            element={<SearchConfigListPage />}
          ></Route>
          <Route path="/ui-config" element={<UIConfigSettingsPage />}></Route>
          <Route
            path="/recommend-config"
            element={<RecommendSettingsPage />}
          ></Route>
          <Route
            path="/business-config"
            element={<BusinessConfigPage />}
          ></Route>
          <Route path="/demo" element={<Demo />}></Route>
        </Routes>
      </ConfigContext.Provider>
    </HashRouter>
  );
}

export default App;
