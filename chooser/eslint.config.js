import js from "@eslint/js";
import reactHooks from "eslint-plugin-react-hooks";
import reactRefresh from "eslint-plugin-react-refresh";
import tseslint from "typescript-eslint";

export default tseslint.config(
  {
    ignores: ["dist", "node_modules"]
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["src/**/*.{ts,tsx}"],
    plugins: {
      "react-hooks": reactHooks,
      "react-refresh": reactRefresh
    },
    languageOptions: {
      ecmaVersion: 2022,
      globals: {
        document: "readonly",
        localStorage: "readonly",
        navigator: "readonly",
        ScrollBehavior: "readonly",
        window: "readonly"
      },
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname
      }
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      "brace-style": ["error", "1tbs", { allowSingleLine: true }],
      curly: ["error", "all"],
      "no-restricted-syntax": [
        "error",
        {
          selector: "Literal[value=/[\\u2010-\\u2015\\u2018\\u2019\\u201C\\u201D]/]",
          message: "Use ASCII hyphen and quotes only."
        },
        {
          selector: "TemplateElement[value.raw=/[\\u2010-\\u2015\\u2018\\u2019\\u201C\\u201D]/]",
          message: "Use ASCII hyphen and quotes only."
        }
      ],
      "react-refresh/only-export-components": ["warn", { allowConstantExport: true }]
    }
  }
);
