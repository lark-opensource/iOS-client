precision highp float; 

varying vec2 upUv; 
varying vec2 downUv;
// uniform sampler2D mattingTexture;
uniform sampler2D originTexture;
uniform sampler2D bgTexture;

// uniform float _uWidth;
// varying vec2 textureCoordinate_face;
varying float zz;
uniform float maskFlag;
const float eps = 0.001;
void main() {
    if (abs(zz) < eps)
    {
        vec4 originColor = texture2D(originTexture, upUv);
        gl_FragColor = originColor;
    }
    else if (abs(zz - 1.0) < eps)
    {
        vec4 bgColor = texture2D(bgTexture, downUv);
//        gl_FragColor = bgColor;
         gl_FragColor = mix(bgColor, vec4(0.0, 0.0, 0.0, 1.0), maskFlag * 0.3);
    }
    else {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
}
