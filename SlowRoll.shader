Shader "Unlit/SlowRoll"
{
    Properties
    {
        // The single image used by this shader
        [NoScaleOffset] _MainTex ("Main Texture", 2D) = "white" {}

        // How fast the image scrolls upward
        _RollSpeed ("Roll Speed", Float) = 0.20

        // How fast the snow pattern changes over time
        _NoiseSpeed ("Noise Speed", Float) = 8.0

        // How dense the snow appears
        _NoiseScale ("Noise Scale", Float) = 160.0

        // How strongly the snow affects the image
        _NoiseIntensity ("Noise Intensity", Range(0.0, 1.0)) = 0.35
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            HLSLPROGRAM

            // Use this function as the vertex shader
            #pragma vertex vert

            // Use this function as the fragment shader
            #pragma fragment frag

            // Include Unity helper functions and built-in variables like _Time
            #include "UnityCG.cginc"

            // Vertex input from the mesh
            struct appdata
            {
                // Object-space vertex position
                float4 vertex : POSITION;

                // Mesh UV coordinates
                float2 uv : TEXCOORD0;
            };

            // Data passed from vertex shader to fragment shader
            struct v2f
            {
                // Clip-space vertex position
                float4 vertex : SV_POSITION;

                // UV coordinates
                float2 uv : TEXCOORD0;
            };

            // Main texture sampler
            sampler2D _MainTex;

            // Material property for roll speed
            float _RollSpeed;

            // Material property for snow animation speed
            float _NoiseSpeed;

            // Material property for snow density scale
            float _NoiseScale;

            // Material property for snow intensity
            float _NoiseIntensity;

            // Vertex shader
            v2f vert(appdata v)
            {
                // Create output struct
                v2f o;

                // Convert vertex position to clip space
                o.vertex = UnityObjectToClipPos(v.vertex);

                // Pass UVs through unchanged
                o.uv = v.uv;

                // Return output
                return o;
            }

            // Small pseudo-random function that returns a value from 0 to 1
            float random(float2 p)
            {
                // Hash the input position into a repeatable random-looking value
                return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
            }

            // Fragment shader
            fixed4 frag(v2f i) : SV_Target
            {
                // Read Unity elapsed time
                float time = _Time.y;

                // Copy the incoming UVs so we can modify them
                float2 uv = i.uv;

                // Roll the image upward continuously and wrap back to the bottom
                uv.y = frac(uv.y - time * _RollSpeed);

                // Sample the rolled image
                fixed4 baseColor = tex2D(_MainTex, uv);

                // Build coordinates for the snow pattern using the same rolled UVs
                // so the noise stays attached to the image as it moves
                float2 noiseUV = floor(uv * _NoiseScale);

                // Generate a random value per noise cell
                float n = random(noiseUV);

                // Convert that random value into a signed value from -1 to 1
                float signedNoise = n * 2.0 - 1.0;

                // Make a black-or-white snow color
                fixed3 snowColor = (signedNoise >= 0.0) ? fixed3(1.0, 1.0, 1.0) : fixed3(0.0, 0.0, 0.0);

                // Use the absolute signed value so stronger random hits create stronger specks
                float snowAmount = abs(signedNoise) * _NoiseIntensity;

                // Blend the original image toward black or white snow
                fixed3 finalRgb = lerp(baseColor.rgb, snowColor, snowAmount);

                // Return the final color with original alpha
                return fixed4(finalRgb, baseColor.a);
            }//end frag function

            ENDHLSL
        }
    }
}
