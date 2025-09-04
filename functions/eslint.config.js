// eslint.config.js
const { defineConfig, globalIgnores } = require("eslint/config");
const js = require("@eslint/js");
const tseslint = require("typescript-eslint");
const importPlugin = require("eslint-plugin-import");
const { fixupPluginRules } = require("@eslint/compat");

module.exports = defineConfig([
  js.configs.recommended,
  ...tseslint.configs.recommended,        // 型情報不要の最小セット
  {
    files: ["**/*.{ts,tsx,js}"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
    },
    plugins: {
      import: fixupPluginRules(importPlugin),
    },
    rules: {
      quotes: ["error", "double"],
      indent: ["error", 2],
      "import/no-unresolved": "off",
      "@typescript-eslint/no-unused-vars": ["error", {
        args: "all",
        argsIgnorePattern: "^_"
      }]
    },
  },
  globalIgnores(["lib/**", "generated/**", "node_modules/**", "eslint.config.js"]),
]);
