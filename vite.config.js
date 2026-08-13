import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'
import tsconfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  plugins: [
    vue(),
    tailwindcss(),
    tsconfigPaths()
  ],

  assetsInclude: ['**/*.lottie'],

  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})