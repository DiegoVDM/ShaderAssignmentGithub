Shader "Unlit/SwirlFade"
{
    Properties
    {
        // First image used in the fade cycle
        [NoScaleOffset] _MainTex ("Image A", 2D) = "white" {}

        // Second image used in the fade cycle
        [NoScaleOffset] _SecondTex ("Image B", 2D) = "white" {}

        // Controls how fast the swirl animation runs
        _SwirlSpeed ("Swirl Speed", Float) = 0.6

        // Controls how fast the image fade cycle runs
        _FadeSpeed ("Fade Speed", Float) = 1.0

        // Controls how strong the swirl distortion is
        _SwirlStrength ("Swirl Strength", Float) = 10.0

        // Controls how far from the center the swirl effect reaches
        _SwirlRadius ("Swirl Radius", Range(0.01, 1.0)) = 0.75
    }

    SubShader
    {
        // Standard opaque unlit pass settings
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            HLSLPROGRAM

            // Tell Unity which function is the vertex shader
            #pragma vertex vert

            // Tell Unity which function is the fragment shader
            #pragma fragment frag

            // Include Unity helper functions and built-in shader variables like _Time
            #include "UnityCG.cginc"

            // Input data coming from the mesh
            struct appdata
            {
                // Vertex position from the mesh
                float4 vertex : POSITION;

                // UV coordinates from the mesh
                float2 uv : TEXCOORD0;
            };

            // Data passed from the vertex shader to the fragment shader
            struct v2f
            {
                // Final clip-space vertex position
                float4 vertex : SV_POSITION;

                // UV coordinates passed along to the fragment shader
                float2 uv : TEXCOORD0;
            };

            // Sampler for the first texture
            sampler2D _MainTex;

            // Sampler for the second texture
            sampler2D _SecondTex;

            // Material property for swirl speed
            float _SwirlSpeed;

            // Material property for fade speed
            float _FadeSpeed;

            // Material property for swirl strength
            float _SwirlStrength;

            // Material property for swirl radius
            float _SwirlRadius;

            // Vertex shader function
            v2f vert(appdata v)
            {
                // Create the output struct
                v2f o;

                // Convert object-space vertex position into clip-space position
                o.vertex = UnityObjectToClipPos(v.vertex);

                // Pass the mesh UVs straight through
                o.uv = v.uv;

                // Return the data to the rasterizer
                return o;
            }

            // Fragment shader function
            fixed4 frag(v2f i) : SV_Target
            {
                // Use Unity's built-in elapsed time and scale it by the material swirl speed
                float swirlTime = _Time.y * _SwirlSpeed;

                // Use Unity's built-in elapsed time and scale it by the material fade speed
                float fadeTime = _Time.y * _FadeSpeed;

                // Create a sine wave that smoothly oscillates from -1 to 1 over time
                float swirlWave = sin(swirlTime);

                // Use a separate wave to drive the fade amount
                float blendAmount = 0.5 + 0.5 * sin(fadeTime);

                // Define the center of the image in UV space
                float2 center = float2(0.5, 0.5);

                // Move the current UV so the center of the image becomes the origin
                float2 offset = i.uv - center;

                // Measure how far this pixel is from the image center
                float radius = length(offset);

                // Create a falloff so pixels near the center swirl more and outer pixels swirl less
                float falloff = saturate(1.0 - (radius / _SwirlRadius));

                // Compute the swirl angle using the animated sine wave and center-weighted falloff
                float angle = _SwirlStrength * swirlWave * falloff * falloff;

                // Compute sine of the rotation angle
                float s = sin(angle);

                // Compute cosine of the rotation angle
                float c = cos(angle);

                // Rotate the centered UV coordinates around the image center
                float2 rotatedOffset = float2(
                    offset.x * c - offset.y * s,
                    offset.x * s + offset.y * c
                );

                // Move the rotated coordinates back into regular 0 to 1 UV space
                float2 swirledUV = center + rotatedOffset;

                // Clamp the UVs so sampling stays inside the texture area
                swirledUV = saturate(swirledUV);

                // Sample the first texture using the swirled UVs
                fixed4 colorA = tex2D(_MainTex, swirledUV);

                // Sample the second texture using the same swirled UVs
                fixed4 colorB = tex2D(_SecondTex, swirledUV);

                // Blend between the two images using the fade amount
                fixed4 finalColor = lerp(colorA, colorB, blendAmount);

                // Output the final pixel color
                return finalColor;
            }

            ENDHLSL
        }
    }
}