part of "graphics.dart";

enum _PrimitiveType {
  points,
  lines,
  lineStrip,
  triangles,
  quads,
  triangleFan;

  int toGLPrimitive() {
    switch (this) {
      case _PrimitiveType.points:
        return GL.POINTS;

      case _PrimitiveType.lines:
        return GL.LINES;

      case _PrimitiveType.triangleFan:
        return GL.TRIANGLE_FAN;

      case _PrimitiveType.lineStrip:
        return GL.LINE_STRIP;

      default:
        return GL.TRIANGLES;
    }
  }
}
