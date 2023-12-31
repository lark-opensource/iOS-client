import React from 'react';
import { App as SiteApp } from '@universe-design/site-template/esm/App';
import { routes } from '../..//routes/routes.config';
import './app.less';

export function App() {
  return <SiteApp routes={routes} platformHoverLog="develop_document_select_hover" />;
}
