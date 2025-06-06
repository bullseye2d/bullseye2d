const String vertexShaderSource = '''
#version 300 es
in vec4 a_position;
in vec2 a_texcoord;
in vec4 a_color;

uniform mat4 u_projectionMatrix;

out vec2 v_texcoord;
out vec4 v_color;

void main() {
    gl_PointSize = 1.0;
    gl_Position = u_projectionMatrix * vec4(a_position.xy, 0.0, 1.0);
    v_texcoord = a_texcoord;
    v_color = a_color;
}
''';

const String fragmentShaderSource = '''
#version 300 es
precision highp float;

in vec2 v_texcoord;
in vec4 v_color;

uniform sampler2D u_texture;

out vec4 out_color;

void main() {
    vec4 tex_color = texture(u_texture, v_texcoord) * v_color;
    out_color = vec4(tex_color.rgb * tex_color.a, tex_color.a);
}
''';
