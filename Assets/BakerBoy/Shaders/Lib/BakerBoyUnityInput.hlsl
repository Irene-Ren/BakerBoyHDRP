// UNITY_SHADER_NO_UPGRADE

#ifndef BAKERBOY_SHADER_VARIABLES_INCLUDED
#define BAKERBOY_SHADER_VARIABLES_INCLUDED

#if defined(STEREO_INSTANCING_ON) && (defined(SHADER_API_D3D11) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE) || defined(SHADER_API_PSSL) || defined(SHADER_API_VULKAN))
#define UNITY_STEREO_INSTANCING_ENABLED
#endif

#if defined(STEREO_MULTIVIEW_ON) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE) || defined(SHADER_API_VULKAN)) && !(defined(SHADER_API_SWITCH))
    #define UNITY_STEREO_MULTIVIEW_ENABLED
#endif

#if defined(UNITY_SINGLE_PASS_STEREO) || defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
#define USING_STEREO_MATRICES
#endif

#if defined(USING_STEREO_MATRICES)
#define glstate_matrix_projection unity_StereoMatrixP[unity_StereoEyeIndex]
#define unity_MatrixV unity_StereoMatrixV[unity_StereoEyeIndex]
#define unity_MatrixInvV unity_StereoMatrixInvV[unity_StereoEyeIndex]
#define unity_MatrixVP unity_StereoMatrixVP[unity_StereoEyeIndex]
#define unity_MatrixInvVP mul(unity_StereoMatrixInvV[unity_StereoEyeIndex], unity_StereoCameraInvProjection[unity_StereoEyeIndex])

#define unity_CameraProjection unity_StereoCameraProjection[unity_StereoEyeIndex]
#define unity_CameraInvProjection unity_StereoCameraInvProjection[unity_StereoEyeIndex]
#define unity_WorldToCamera unity_StereoWorldToCamera[unity_StereoEyeIndex]
#define unity_CameraToWorld unity_StereoCameraToWorld[unity_StereoEyeIndex]
#define _WorldSpaceCameraPos unity_StereoWorldSpaceCameraPos[unity_StereoEyeIndex]
#endif

#define UNITY_LIGHTMODEL_AMBIENT (glstate_lightmodel_ambient * 2)

// ----------------------------------------------------------------------------

// Time (t = time since current level load) values from Unity

float4 _TimeParameters; // t, sin(t), cos(t)

#if !defined(USING_STEREO_MATRICES)
#endif

// ----------------------------------------------------------------------------

// Block Layout should be respected due to SRP Batcher
CBUFFER_START(UnityPerDraw)

// Light Indices block feature
// These are set internally by the engine upon request by RendererConfiguration.
real4 unity_LightData;
real4 unity_LightIndices[2];

CBUFFER_END

#if defined(UNITY_STEREO_MULTIVIEW_ENABLED) || ((defined(UNITY_SINGLE_PASS_STEREO) || defined(UNITY_STEREO_INSTANCING_ENABLED)) && (defined(SHADER_API_GLCORE) || defined(SHADER_API_GLES3) || defined(SHADER_API_METAL) || defined(SHADER_API_VULKAN)))
    #define GLOBAL_CBUFFER_START(name)    cbuffer name {
    #define GLOBAL_CBUFFER_END            }
#else
    #define GLOBAL_CBUFFER_START(name)    CBUFFER_START(name)
    #define GLOBAL_CBUFFER_END            CBUFFER_END
#endif

#if defined(USING_STEREO_MATRICES)
GLOBAL_CBUFFER_START(UnityStereoGlobals)
float4x4 unity_StereoMatrixP[2];
float4x4 unity_StereoMatrixV[2];
float4x4 unity_StereoMatrixInvV[2];
float4x4 unity_StereoMatrixVP[2];

float4x4 unity_StereoCameraProjection[2];
float4x4 unity_StereoCameraInvProjection[2];
float4x4 unity_StereoWorldToCamera[2];
float4x4 unity_StereoCameraToWorld[2];

float3 unity_StereoWorldSpaceCameraPos[2];
float4 unity_StereoScaleOffset[2];
GLOBAL_CBUFFER_END
#endif

#if defined(USING_STEREO_MATRICES) && defined(UNITY_STEREO_MULTIVIEW_ENABLED)
GLOBAL_CBUFFER_START(UnityStereoEyeIndices)
    float4 unity_StereoEyeIndices[2];
GLOBAL_CBUFFER_END
#endif

#if defined(UNITY_STEREO_MULTIVIEW_ENABLED) && defined(SHADER_STAGE_VERTEX)
// OVR_multiview
// In order to convey this info over the DX compiler, we wrap it into a cbuffer.
#if !defined(UNITY_DECLARE_MULTIVIEW)
#define UNITY_DECLARE_MULTIVIEW(number_of_views) GLOBAL_CBUFFER_START(OVR_multiview) uint gl_ViewID; uint numViews_##number_of_views; GLOBAL_CBUFFER_END
#define UNITY_VIEWID gl_ViewID
#endif
#endif

#if defined(UNITY_STEREO_MULTIVIEW_ENABLED) && defined(SHADER_STAGE_VERTEX)
#define unity_StereoEyeIndex UNITY_VIEWID
UNITY_DECLARE_MULTIVIEW(2);
#elif defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
static uint unity_StereoEyeIndex;
#elif defined(UNITY_SINGLE_PASS_STEREO)
GLOBAL_CBUFFER_START(UnityStereoEyeIndex)
int unity_StereoEyeIndex;
GLOBAL_CBUFFER_END
#endif


// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------

// TODO: all affine matrices should be 3x4.
// TODO: sort these vars by the frequency of use (descending), and put commonly used vars together.
// Note: please use UNITY_MATRIX_X macros instead of referencing matrix variables directly.
float4x4 _PrevViewProjMatrix;
float4x4 _ViewProjMatrix;
float4x4 _NonJitteredViewProjMatrix;
float4x4 _ViewMatrix;
float4x4 _ProjMatrix;
float4x4 _InvViewProjMatrix;
float4x4 _InvViewMatrix;
float4x4 _InvProjMatrix;
float4   _InvProjParam;
float4   _ScreenSize;       // {w, h, 1/w, 1/h}
float4   _FrustumPlanes[6]; // {(a, b, c) = N, d = -dot(N, P)} [L, R, T, B, N, F]

float4x4 OptimizeProjectionMatrix(float4x4 M)
{
    // Matrix format (x = non-constant value).
    // Orthographic Perspective  Combined(OR)
    // | x 0 0 x |  | x 0 x 0 |  | x 0 x x |
    // | 0 x 0 x |  | 0 x x 0 |  | 0 x x x |
    // | x x x x |  | x x x x |  | x x x x | <- oblique projection row
    // | 0 0 0 1 |  | 0 0 x 0 |  | 0 0 x x |
    // Notice that some values are always 0.
    // We can avoid loading and doing math with constants.
    M._21_41 = 0;
    M._12_42 = 0;
    return M;
}

#endif // UNIVERSAL_SHADER_VARIABLES_INCLUDED
