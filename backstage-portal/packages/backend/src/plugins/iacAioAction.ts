/*
 * Custom Scaffolder Action: IaC All-in-One
 * Gọi Python backend (port 7070) để đọc Vault + chạy Terraform với log REALTIME
 */
import { createTemplateAction } from '@backstage/plugin-scaffolder-node';
import { spawn } from 'child_process';
import { Writable } from 'stream';

export function createIacTerraformAction() {
  return createTemplateAction<any, any>({
    id: 'iac:terraform',
    description: 'Chạy Terraform plan/apply cho infrastructure layer, đọc config từ Vault (log realtime)',
    schema: {
      input: {
        type: 'object',
        required: ['environment', 'layers', 'action'],
        properties: {
          environment: { type: 'string', description: 'dev/stg/prd' },
          layers: { type: 'string', description: 'network,compute,jenkins,rancher' },
          action: { type: 'string', description: 'plan hoặc apply' },
          project_name: { type: 'string', description: 'Tên project' },
        },
      },
    },

    async handler(ctx) {
      const { environment, layers, action, project_name } = ctx.input;

      // Join array thành string nếu layers là array
      const layersStr = Array.isArray(layers) ? layers.join(',') : String(layers);

      ctx.logger.info(`🚀 IaC AIO: project=${project_name}, env=${environment}, layers=${layersStr}, action=${action}`);

      const apiUrl = `http://localhost:7070/api/iac-terraform-stream?env=${environment}&layers=${encodeURIComponent(layersStr)}&action=${action}`;

      ctx.logger.info(`📡 Streaming from: ${apiUrl}`);

      // Dùng curl spawn để stream từng dòng log
      const curl = spawn('curl', ['-s', '-N', apiUrl]);

      const logStream = new Writable({
        write(chunk: Buffer, _encoding, callback) {
          const line = chunk.toString().trim();
          if (line) {
            ctx.logger.info(line);
          }
          callback();
        },
      });

      curl.stdout.pipe(logStream);
      curl.stderr.pipe(logStream);

      await new Promise<void>((resolve, reject) => {
        curl.on('close', (code) => {
          if (code === 0) {
            ctx.logger.info('✅ IaC AIO completed');
            ctx.output('status', 'success');
            resolve();
          } else {
            ctx.logger.error(`❌ IaC AIO failed (exit=${code})`);
            ctx.output('status', 'failed');
            reject(new Error(`curl exit code ${code}`));
          }
        });
        curl.on('error', (err) => {
          ctx.logger.error(`❌ Cannot connect: ${err.message}`);
          ctx.output('status', 'failed');
          reject(err);
        });
      });
    },
  });
}
