/**
 * 接口适配层导出
 */
export { 
  AIModelAdapter, 
  CloudAIModelAdapter, 
  LocalAIModelAdapter,
  AIModelFactory 
} from './AIModelAdapter';
export type { 
  AIModelConfig, 
  ChatMessage, 
  AIResponse 
} from './AIModelAdapter';

export {
  StorageAdapter,
  PreferencesStorageAdapter,
  FileStorageAdapter,
  StorageFactory
} from './StorageAdapter';
export type {
  StorageConfig
} from './StorageAdapter';
