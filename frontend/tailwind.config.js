/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f5f9f1',
          100: '#e8f1e0',
          200: '#d4e4c1',
          300: '#a8d87f',
          400: '#8bbf4d',
          500: '#6da836',
          600: '#4a7c2e',
          700: '#2D5016',
          800: '#1B3109',
          900: '#0f1a05',
        },
        accent: {
          50: '#fffbeb',
          100: '#fef3c7',
          200: '#fde68a',
          300: '#fcd34d',
          400: '#e8a800',
          500: '#d4a000',
          600: '#b88600',
          700: '#8b6600',
          800: '#654000',
          900: '#3d2500',
        },
      },
    },
  },
  plugins: [],
}




