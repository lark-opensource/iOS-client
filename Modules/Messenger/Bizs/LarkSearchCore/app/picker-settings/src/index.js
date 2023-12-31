import React from "react";
import ReactDOM from "react-dom/client";
import "./index.css";
import App from "./App";
import reportWebVitals from "./reportWebVitals";
import configString from "./config/config.json";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";

const initialState = window.__INITIAL_DATA__ || JSON.parse(configString);
// setInterval(() => {
//   console.log("initialState:", window.__INITIAL_DATA__);
// }, 1000);
const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(<App initialState={initialState} />);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
