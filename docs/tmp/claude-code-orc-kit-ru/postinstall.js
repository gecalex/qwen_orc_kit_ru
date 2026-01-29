#!/usr/bin/env node

/**
 * Скрипт post-install для Claude Code Orchestrator Kit
 *
 * Этот скрипт запускается автоматически после npm install и помогает пользователям
 * правильно настроить набор.
 */

import { welcome } from './index.js';
import { existsSync } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Проверить, существуют ли необходимые файлы
 */
function checkInstallation() {
  const requiredPaths = [
    '.claude',
    '.claude/agents',
    '.claude/commands',
    '.claude/skills',
    'mcp',
    'CLAUDE.md',
    'README.md',
  ];

  const missing = requiredPaths.filter(
    path => !existsSync(join(__dirname, path))
  );

  if (missing.length > 0) {
    console.error('❌ Установка неполная. Отсутствуют файлы:');
    missing.forEach(path => console.error(`   - ${path}`));
    process.exit(1);
  }

  return true;
}

/**
 * Основная подпрограмма post-install
 */
async function main() {
  try {
    // Проверка целостности установки
    checkInstallation();

    // Отображение приветственного сообщения с инструкциями по настройке
    welcome();

    // Проверка существования .env.local
    if (!existsSync(join(__dirname, '.env.local'))) {
      console.log('\n⚠️  Не забудьте создать .env.local из .env.example\n');
    }

    // Успех
    process.exit(0);
  } catch (error) {
    console.error('❌ Post-install не удался:', error.message);
    process.exit(1);
  }
}

// Запуск post-install
main();
