part of 'graphics.dart';

typedef GL = WebGLRenderingContext;
typedef GL2 = WebGL2RenderingContext;

WebGLShader? _compileShader(GL2 gl, String source, int type) {
  final shader = gl.createShader(type);
  if (shader == null) {
    error('Could not create shader.');
    return null;
  }

  gl.shaderSource(shader, source);
  gl.compileShader(shader);

  if (gl.getShaderParameter(shader, GL.COMPILE_STATUS) == false.toJS) {
    error('Could not compile shader: ${gl.getShaderInfoLog(shader)}');
    gl.deleteShader(shader);
    return null;
  }
  return shader;
}

WebGLProgram? _createProgramFromSources(GL2 gl, String vertexShaderSource, String fragmentShaderSource) {
  final vertexShader = _compileShader(gl, vertexShaderSource, GL.VERTEX_SHADER);
  final fragmentShader = _compileShader(gl, fragmentShaderSource, GL.FRAGMENT_SHADER);

  if (vertexShader == null || fragmentShader == null) {
    return null;
  }

  final program = gl.createProgram();
  if (program == null) {
    error('Could not create program.');
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);
    return null;
  }

  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);

  if (gl.getProgramParameter(program, GL.LINK_STATUS) == false.toJS) {
    error('Could not link program: ${gl.getProgramInfoLog(program)}');
    gl.deleteProgram(program);
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);
    return null;
  }

  gl.deleteShader(vertexShader);
  gl.deleteShader(fragmentShader);

  return program;
}
