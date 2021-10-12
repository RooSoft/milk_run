module.exports = {
  mode: 'jit',
  purge: [
    './js/**/*.js',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    fontFamily: {
      "branding": ["Krona One"],
      "username": ["Special Elite"],
      "nodename": ["Maven Pro"],
      "price": ["Aclonica"]
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
