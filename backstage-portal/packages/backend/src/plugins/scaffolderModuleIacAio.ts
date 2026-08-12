/*
 * Backend Module: Đăng ký custom IaC AIO scaffolder action
 */
import { createBackendModule } from '@backstage/backend-plugin-api';
import { scaffolderActionsExtensionPoint } from '@backstage/plugin-scaffolder-node';
import { createIacTerraformAction } from './iacAioAction';

const scaffolderModuleIacAio = createBackendModule({
  pluginId: 'scaffolder',
  moduleId: 'iac-aio',
  register(reg) {
    reg.registerInit({
      deps: {
        scaffolder: scaffolderActionsExtensionPoint,
      },
      async init({ scaffolder }) {
        scaffolder.addActions(createIacTerraformAction());
      },
    });
  },
});

export default scaffolderModuleIacAio;
