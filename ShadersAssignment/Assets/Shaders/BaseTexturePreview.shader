Shader "Unlit/BaseTexturePreview"
{
    Properties
    {
        // Main texture shown on the material
        [NoScaleOffset] _MainTex ("Main Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            HLSLPROGRAM

            // Vertex shader function name
            #pragma vertex vert

            // Fragment shader function name
            #pragma fragment frag

            // Unity helper functions like UnityObjectToClipPos
            #include "UnityCG.cginc"

            // Data coming in from the mesh
            struct appdata
            {
                float4 vertex : POSITION;   // Object-space vertex position
                float2 uv     : TEXCOORD0;  // Mesh UV coordinates
            };

            // Data sent from vertex shader to fragment shader
            struct v2f
            {
                float4 vertex : SV_POSITION; // Clip-space position
                float2 uv     : TEXCOORD0;   // UV passed to fragment shader
            };

            // Texture sampler for the material's main texture
            sampler2D _MainTex;

            // Vertex shader
            v2f vert(appdata v)
            {
                v2f o;

                // Convert object-space vertex into clip-space
                o.vertex = UnityObjectToClipPos(v.vertex);

                // Pass UVs straight through
                o.uv = v.uv;

                return o;
            }

            // Fragment shader
            fixed4 frag(v2f i) : SV_Target
            {
                // Sample the texture using the interpolated UV
                fixed4 color = tex2D(_MainTex, i.uv);

                // Output the texture color directly
                return color;
            }

            ENDHLSL
        }
    }
}
