
attribute vec3 attPosition;
attribute vec2 attUV;

varying vec2 upUv;
varying vec2 downUv;
// varying vec2 textureCoordinate_face;
varying float zz;
// uniform int bgWid;
// uniform int bgHei;
// varying float bgh_w;
// uniform float rotate;
uniform float touch_dy;
uniform float touch_y;
// uniform float touch_dy;
// 1000 750 
// 1280 720
void main() {
    // vec3 pos = attPosition;
    // vec2 face_uv = attUV.xy;
    
    // mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    // pos.xy = pos.xy * rot;
    
    // bgh_w = float(bgHei) / float(bgWid);
    // if (rotate == 1.0 || rotate == 3.0) 
    // {
    //     bgh_w = 1.0 / bgh_w;
    // }
    // float middle_size = bgh_w * 0.5625; // 720.0 / 1280.0
    // float left_size = 1.0 - middle_size;
    // if (attPosition.z == 0.0)
    // {
    //     pos.y = pos.y * middle_size;
    //     face_uv.y = ((face_uv.y * 2.0 - 1.0) * middle_size + 1.0) * 0.5;
    // } 
    // else if (attPosition.z == -1.0) {
    //     pos.y = pos.y * left_size * 0.5 -  (1.0 - left_size * 0.5);
    // } else{
    //     pos.y = pos.y * left_size * 0.5 + (1.0 - left_size * 0.5);
    // }
    // pos.z = 0.0;
    // zz  = attPosition.z;

    // gl_Position = vec4(pos, 1.);
    // textureCoordinate = attUV.xy;
    // // face_uv.x = face_uv.x * 1280.0 * 720.0 / 750.0 / 1000.0;
    // textureCoordinate_face = face_uv;
    zz = attPosition.z;
    vec2 xy = attPosition.xy;
    vec2 uv = attUV.xy;
    // xy.y = xy.y + touch_dy;
    uv.y = uv.y + touch_dy;
    gl_Position = vec4(xy, 0.0, 1.0);
    upUv = uv;
    downUv = uv;

}
