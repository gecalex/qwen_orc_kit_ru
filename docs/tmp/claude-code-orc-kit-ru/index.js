#!/usr/bin/env node

/**
 * Claude Code Orchestrator Kit
 *
 * Главная точка входа для npm-пакета.
 * Этот файл предоставляет программный доступ к утилитам набора.
 */

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Чтение package.json для получения информации о версии
const packageJson = JSON.parse(
  readFileSync(join(__dirname, 'package.json'), 'utf-8')
);

/**
 * Получить версию набора оркестратора
 */
export function getVersion() {
  return packageJson.version;
}

/**
 * Получить путь к директории установки
 */
export function getInstallPath() {
  return __dirname;
}

/**
 * Получить пути к ключевым директориям
 */
export function getPaths() {
  return {
    root: __dirname,
    claude: join(__dirname, '.claude'),
    agents: join(__dirname, '.claude', 'agents'),
    commands: join(__dirname, '.claude', 'commands'),
    skills: join(__dirname, '.claude', 'skills'),
    mcp: join(__dirname, 'mcp'),
    docs: join(__dirname, 'docs'),
  };
}

/**
 * Отобразить приветственное сообщение
 */
export function welcome() {
  console.log(`
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║   🎼 Claude Code Orchestrator Kit v${packageJson.version}                 ║
║                                                                ║
║   Профессиональная система автоматизации и оркестрации        ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

📦 Пакет успешно установлен!

🚀 Следующие шаги:

1. Настройте переменные окружения:
   cp .env.example .env.local
   # Отредактируйте .env.local с вашими учётными данными

2. Выберите конфигурацию MCP:
   npm run setup
   # Или: bash switch-mcp.sh

3. Перезапустите Claude Code для применения изменений

📚 Документация: ${packageJson.homepage}
💬 Проблемы: ${packageJson.bugs.url}

Удачного программирования с Claude! 🤖
`);
}

// Если запускается напрямую из командной строки
if (process.argv[1] === __filename) {
  welcome();
}

// Экспорт всех утилит
export default {
  getVersion,
  getInstallPath,
  getPaths,
  welcome,
};
