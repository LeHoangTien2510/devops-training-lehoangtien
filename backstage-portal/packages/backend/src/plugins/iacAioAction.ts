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
      output: {
        type: 'object',
        properties: {
          status: { type: 'string' },
          environment: { type: 'string' },
          vault_data: {
            type: 'object',
            description: 'Infrastructure config từ Vault (cluster_name, vpc_cidr, ...)',
          },
        },
      },
    },

    async handler(ctx) {
      const { environment, layers, action, project_name } = ctx.input;

      // Join array thành string nếu layers là array
      const layersStr = Array.isArray(layers) ? layers.join(',') : String(layers);

      ctx.logger.info(`🚀 IaC AIO: project=${project_name}, env=${environment}, layers=${layersStr}, action=${action}`);

      // ─── Fetch Vault data trước để output cho catalog ───
      let vaultData: Record<string, any> = {};
      try {
        const vaultResp = await fetch(`http://localhost:7070/api/iac-vault/${environment}/infrastructure`);
        vaultData = await vaultResp.json();
        ctx.logger.info(`🔐 Vault data loaded: cluster=${vaultData.cluster_name}, vpc=${vaultData.vpc_cidr}`);
        ctx.output('vault_data', vaultData);
      } catch (e) {
        ctx.logger.warn(`⚠️ Could not fetch Vault data: ${e}`);
      }

      // ─── Stream terraform ───
      const apiUrl = `http://localhost:7070/api/iac-terraform-stream?env=${environment}&layers=${encodeURIComponent(layersStr)}&action=${action}`;
      ctx.logger.info(`📡 Streaming from: ${apiUrl}`);

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
        curl.on('close', async (code) => {
          if (code === 0) {
            ctx.logger.info('✅ IaC AIO completed');
            ctx.output('status', 'success');

            // ─── Register vào catalog: ghi file persistent + tạo Location ───
            try {
              const fs = await import('fs');
              const path = await import('path');
              const catalogDir = '/home/tien/work/devops-training-lehoangtien/backstage-portal/catalog';
              if (!fs.existsSync(catalogDir)) fs.mkdirSync(catalogDir, { recursive: true });

              const entityName = `${project_name}-${environment}`;
              const entityYaml = `apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: ${entityName}
  title: ${project_name} (${environment})
  description: IaC project
  tags:
    - iac
    - terraform
    - ${environment}
  annotations:
    iac.environment: ${environment}
    iac.project: ${project_name}
    iac.cluster-name: ${vaultData.cluster_name || 'N/A'}
    iac.vpc-cidr: ${vaultData.vpc_cidr || 'N/A'}
spec:
  type: infrastructure
  owner: user:guest
  lifecycle: production
`;
              const filePath = path.join(catalogDir, `${entityName}.yaml`);
              fs.writeFileSync(filePath, entityYaml);
              ctx.logger.info(`📄 Written: ${filePath}`);

              // Đăng ký Location qua guest auth (fallback nếu API 401 vẫn OK vì app-config scan)
              const guestResp = await fetch('http://localhost:7007/api/auth/guest/refresh');
              const guestData: any = await guestResp.json();
              const guestToken = guestData?.backstageIdentity?.token || '';
              if (guestToken) {
                await fetch('http://localhost:7007/api/catalog/locations', {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${guestToken}`,
                  },
                  body: JSON.stringify({ type: 'file', target: filePath }),
                });
                ctx.logger.info(`📋 Registered in Catalog: ${entityName}`);
              }
            } catch (e: any) {
              ctx.logger.warn(`⚠️ Catalog register error: ${e.message}`);
            }

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
