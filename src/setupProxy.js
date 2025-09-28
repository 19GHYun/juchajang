const { createProxyMiddleware } = require('http-proxy-middleware');

module.exports = function(app) {
  console.log('🔧 setupProxy.js 로드됨!');

  // Spring API 프록시 (번호판 스캔)
  app.use(
    '/api/v1/plates',
    createProxyMiddleware({
      target: 'https://j13c108.p.ssafy.io',
      changeOrigin: true,
      logLevel: 'debug',
      onProxyReq: (proxyReq, req, res) => {
        console.log('🌸 Spring API 프록시 요청:', req.url);
      }
    })
  );

  console.log('✅ 프록시 설정 완료!');
};