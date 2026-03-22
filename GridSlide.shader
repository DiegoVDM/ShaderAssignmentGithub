Shader "Unlit/GridSlide"
{
    Properties
    {
        // The single image used by this shader
        [NoScaleOffset] _MainTex ("Main Texture", 2D) = "white" {}

        // Controls how fast the full 4-phase cycle plays
        _CycleSpeed ("Cycle Speed", Float) = 0.35
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

            // Input data coming from the mesh
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

                // UV coordinates passed to the fragment shader
                float2 uv : TEXCOORD0;
            };

            // Texture sampler for the material's image
            sampler2D _MainTex;

            // Material property controlling animation speed
            float _CycleSpeed;

            // Vertex shader
            v2f vert(appdata v)
            {
                // Create output struct
                v2f o;

                // Convert object-space vertex into clip-space
                o.vertex = UnityObjectToClipPos(v.vertex);

                // Pass UVs through unchanged
                o.uv = v.uv;

                // Return output data
                return o;
            }

            // Fragment shader
            fixed4 frag(v2f i) : SV_Target
            {
                // Hard-code the grid to 4x4 to match the assignment
                float gridCount = 4.0;

                // Scale UVs into grid space so each whole number step is one cell
                float2 gridUV = i.uv * gridCount;

                // Get the integer cell coordinate this pixel belongs to
                float2 cell = floor(gridUV);

                // Get the local UV inside the current cell, from 0 to 1
                float2 localUV = frac(gridUV);

                // Determine whether this cell belongs to A1 or A2
                // Even parity = A1, odd parity = A2
                float parity = fmod(cell.x + cell.y, 2.0);

                // Build a looping 0-to-1 cycle over time
                float cycle = frac(_Time.y * _CycleSpeed);

                // Expand the cycle into 4 phases
                float phaseValue = cycle * 4.0;

                // Get the current phase number: 0, 1, 2, or 3
                float phase = floor(phaseValue);

                // Get the progress through the current phase, from 0 to 1
                float phaseT = frac(phaseValue);

                // These store the start and end offsets for the current phase
                float2 startOffset;
                float2 endOffset;

                // A1 group follows: Up -> Left -> Down -> Right
                if (parity < 0.5)
                {
                    if (phase < 1.0)
                    {
                        startOffset = float2(0.0, 0.0);
                        endOffset   = float2(0.0, 1.0);
                    }
                    else if (phase < 2.0)
                    {
                        startOffset = float2(0.0, 1.0);
                        endOffset   = float2(-1.0, 1.0);
                    }
                    else if (phase < 3.0)
                    {
                        startOffset = float2(-1.0, 1.0);
                        endOffset   = float2(-1.0, 0.0);
                    }
                    else
                    {
                        startOffset = float2(-1.0, 0.0);
                        endOffset   = float2(0.0, 0.0);
                    }
                }
                // A2 group follows: Down -> Right -> Up -> Left
                else
                {
                    if (phase < 1.0)
                    {
                        startOffset = float2(0.0, 0.0);
                        endOffset   = float2(0.0, -1.0);
                    }
                    else if (phase < 2.0)
                    {
                        startOffset = float2(0.0, -1.0);
                        endOffset   = float2(1.0, -1.0);
                    }
                    else if (phase < 3.0)
                    {
                        startOffset = float2(1.0, -1.0);
                        endOffset   = float2(1.0, 0.0);
                    }
                    else
                    {
                        startOffset = float2(1.0, 0.0);
                        endOffset   = float2(0.0, 0.0);
                    }
                }

                // Smoothly interpolate between the phase start and phase end
                float2 cellOffset = lerp(startOffset, endOffset, phaseT);

                // Build the source UV by taking the original cell position,
                // adding the animated cell offset, then adding the local UV
                float2 sourceUV = (cell + cellOffset + localUV) / gridCount;

                // Wrap UVs so tiles that move off one side re-enter from the other
                sourceUV = frac(sourceUV);

                // Sample the texture using the animated source UV
                fixed4 color = tex2D(_MainTex, sourceUV);

                // Return the final pixel color
                return color;
            }

            ENDHLSL
        }
    }
}
