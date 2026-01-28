/*
 * Local development config - standalone copy of next.config.js with rewrites
 * to proxy backend requests through Next.js, avoiding CORS issues.
 */

const CopyWebpackPlugin = require('copy-webpack-plugin')
const path = require('path')

const CESIUM_SOURCE = path.join(__dirname, '../node_modules/cesium/Source')

const HLS_SOURCE = path.join(
  __dirname,
  '../node_modules/hls.js/dist/hls.min.js'
)
const PUBLIC_HLS_PATH = '../public/hls.js/'

const nextConfig = {
  transpilePackages: [
    'ol',
    '@mui/material',
    'react-charts',
    'd3-scale',
    'd3-color',
    'd3-interpolate',
  ],
  experimental: { esmExternals: 'loose' },

  // Rewrites to proxy backend requests (avoids CORS)
  async rewrites() {
    return [
      {
        source: '/graphql/:path*',
        destination: 'https://octocx/graphql/:path*',
      },
      {
        source: '/geoserver/:path*',
        destination: 'https://octocx/geoserver/:path*',
      },
      {
        source: '/tile-proxy/:path*',
        destination: 'https://octocx/tile-proxy/:path*',
      },
      {
        source: '/docs/:path*',
        destination: 'https://octocx/docs/:path*',
      },
      {
        source: '/transfer/:path*',
        destination: 'https://octocx/transfer/:path*',
      },
    ]
  },

  webpack: (config, { webpack, isServer }) => {
    // Add loader for markdown files
    config.module.rules.push({
      test: /\.md$/,
      use: 'raw-loader',
    })

    // Add loader for svg files
    config.module.rules.push({
      test: /\.svg$/,
      use: ['@svgr/webpack'],
    })

    // Strip cesium pragmas and warnings
    config.module.rules.push({
      test: /\.js$/,
      enforce: 'pre',
      include: path.resolve(CESIUM_SOURCE),
      use: [
        {
          loader: 'strip-pragma-loader',
          options: {
            pragmas: {
              debug: false,
            },
          },
        },
      ],
    })

    // Set global location for cesium base url
    config.plugins.push(
      new webpack.DefinePlugin({
        CESIUM_BASE_URL: JSON.stringify('/Cesium'),
      })
    )

    config.plugins.push(
      // Suppress warnings "require function is used in a way in which dependencies cannot be statically extracted"
      new webpack.ContextReplacementPlugin(/cesium\/Source\/Core/, ctx => {
        const { resource, context, dependencies } = ctx
        if (resource === context) {
          dependencies.forEach(dependency => (dependency.critical = false))
        }
        return ctx
      })
    )

    config.module = {
      ...config.module,
      exprContextCritical: false,
    }

    // Cesium package json exports are wrong
    config.resolve.exportsFields = []

    if (!isServer) {
      config.plugins.push(
        new CopyWebpackPlugin({
          patterns: [
            {
              from: HLS_SOURCE,
              to: PUBLIC_HLS_PATH,
            },
          ],
        })
      )

      // MGRS
      config.plugins.push(
        new CopyWebpackPlugin({
          patterns: [
            {
              from: path.join(
                __dirname,
                '..',
                'node_modules',
                '@common-mgrs',
                'mgrs',
                'src',
                'scripts',
                'features',
                'grid_zones_mgrs_grid.json'
              ),
              to: path.join(
                __dirname,
                'public',
                'mgrs',
                'grid_zones_mgrs_grid.json'
              ),
            },
            {
              from: path.join(
                __dirname,
                '..',
                'node_modules',
                '@common-mgrs',
                'mgrs',
                'src',
                'scripts',
                'features',
                'mgrs.pmtiles'
              ),
              to: path.join(__dirname, 'public', 'mgrs', 'mgrs.pmtiles'),
            },
          ],
        })
      )
    }

    return config
  },
  publicRuntimeConfig: {
    SITE: process.env.SITE,
    NEXTAUTH_URL: process.env.NEXTAUTH_URL,
    GRAPHQL_BASE_URL: process.env.GRAPHQL_BASE_URL,
    GEOSERVER_BASE_URL: process.env.GEOSERVER_BASE_URL,
    NODE_BASE_URL: process.env.NODE_BASE_URL,
    TILE_SERVER_ZYX_URL: process.env.TILE_SERVER_ZYX_URL,
    TILE_SERVER_ZXY_URL: process.env.TILE_SERVER_ZXY_URL,
    IDP_BASE_URL: process.env.IDP_BASE_URL,
    IDP_REDIRECT_URL: process.env.IDP_REDIRECT_URL || process.env.IDP_BASE_URL,
    AITR_BASE_URL: process.env.AITR_BASE_URL,
    AITR_MAX_VLM_STREAMS: process.env.AITR_MAX_VLM_STREAMS,
    ONE_SHOT_BASE_URL: process.env.ONE_SHOT_BASE_URL,
    SEMANTIC_EDGE_URL: process.env.SEMANTIC_EDGE_URL,
    TRANSFER_BASE_URL: process.env.TRANSFER_BASE_URL,
    NEXTAUTH_SECRET: process.env.NEXTAUTH_SECRET,
    NEXTAUTH_URL_INTERNAL: process.env.NEXTAUTH_URL_INTERNAL,
    CLIENT_ID: process.env.CLIENT_ID || 'login-client',
    CLIENT_SECRET: process.env.CLIENT_SECRET || 'secret',
    CLIENT_SCOPE: process.env.CLIENT_SCOPE || 'openid profile email',
    DOCUMENTATION_SERVER: process.env.DOCUMENTATION_SERVER,
    FEATURE_FLAGS: process.env.FEATURE_FLAGS
      ? process.env.FEATURE_FLAGS.split(',')
      : [],
    SA_ICON_THRESHOLD: process.env.SA_ICON_THRESHOLD || 11,
    SA_GEO_THRESHOLD: process.env.SA_GEO_THRESHOLD || 14,
    DEPLOYMENT_TYPE: process.env.DEPLOYMENT_TYPE || 'hub',
    LOWEST_SYSTEM_CLASSIFICATION: process.env.LOWEST_SYSTEM_CLASSIFICATION,
    SYSTEM_MESSAGE: `<div id="consent">
        <p>
            You are about to access a United States Government (USG)-authorized information system, which includes:  (1) This computer; (2) This computer network; (3) All computers connected to this network; and (4) all devices and storage media attached to this network or to a computer on this network.
        </p>
        <p>
            This information system is provided for USG-authorized use only. Unauthorized or improper use of this system may result in disciplinary action, as well as civil and criminal penalties.
        </p>
        <p>
            By using this information system, you understand and consent to the following:
        </p>
        <ul>
            <li>You have no reasonable expectation of privacy regarding communications or data transiting or stored on this information system;</li>
            <li>At any time, and for any lawful USG purpose, the USG may monitor, intercept, and search any communication or data transiting or stored on this information system; and</li>
            <li>Any communications or data transiting or stored on this information system may be disclosed or used for any lawful USG purpose. </li>
        </ul>
        <p>
            All communications or data using this information system, even if personal in nature and without any relevance to official business, is subject to federal retention and disclosure requirements in accordance with applicable federal law. By using this information system you consent to and agree to be bound by these conditions, which may not be altered without prior specific written official approval.
        </p>
    </div>`,
    STREAM_SERVER_HOST: process.env.STREAM_SERVER_HOST,
    STREAM_ABR_ENABLED: process.env.STREAM_ABR_ENABLED == 'true',
    STREAM_SERVER_WEBRTC_PORT: process.env.STREAM_SERVER_WEBRTC_PORT,
    STREAM_SERVER_LLHLS_PORT: process.env.STREAM_SERVER_LLHLS_PORT,
    STREAM_SERVER_LLHLS_ENABLED:
      process.env.STREAM_SERVER_LLHLS_ENABLED == 'true',
    STREAM_SERVER_WEBRTC_ENABLED:
      process.env.STREAM_SERVER_WEBRTC_ENABLED == 'true',
    OVENPLAYER_DEBUG: process.env.OVENPLAYER_DEBUG == 'true',
    USE_CUSTOM_BRANDING: process.env.USE_CUSTOM_BRANDING == 'true',
    BRAND_COLOR: process.env.BRAND_COLOR,
    TRANSFER_DESTINATIONS: process.env.TRANSFER_DESTINATIONS
      ? process.env.TRANSFER_DESTINATIONS.split(',')
      : [],
    APP_TYPE: process.env.APP_TYPE,
    VERSION: process.env.VERSION,
  },
}

module.exports = nextConfig
