import 'dart:ffi';
import 'dart:typed_data';
import '../native/rnnoise_ffi.dart';

/// Adapta chunks de tamaño variable (flutter_sound) al frame fijo de RNNoise
/// (480 muestras PCM16 = 960 bytes). Llama RNNoise por cada frame completo y
/// emite el audio limpio.
class RnnoiseProcessor {
  // 480 muestras × 2 bytes = 960 bytes por frame.
  static const int _bytesPerFrame = RnnoiseFfi.frameSize * 2;

  final RnnoiseFfi _ffi = RnnoiseFfi();
  final _buffer = <int>[];

  void init() => _ffi.init();

  /// Procesa [input] (PCM16 LE, 16 kHz, mono) y devuelve los bytes limpios.
  /// Puede devolver menos bytes de los recibidos si el buffer no llena un frame.
  Uint8List process(Uint8List input) {
    _buffer.addAll(input);

    final output = BytesBuilder(copy: false);

    while (_buffer.length >= _bytesPerFrame) {
      final frameBytes = _buffer.sublist(0, _bytesPerFrame);
      _buffer.removeRange(0, _bytesPerFrame);
      output.add(_processFrame(frameBytes));
    }

    return output.toBytes();
  }

  Uint8List _processFrame(List<int> bytes) {
    // PCM16 LE → float32 (rango [-32768, 32767], no normalizado)
    final input = _ffi.inputBuf;
    for (int i = 0; i < RnnoiseFfi.frameSize; i++) {
      final lo = bytes[i * 2];
      final hi = bytes[i * 2 + 1];
      int sample = (hi << 8) | lo;
      if (sample >= 0x8000) sample -= 0x10000; // sign-extend
      (input + i).value = sample.toDouble();
    }

    _ffi.processFrame();

    // float32 → PCM16 LE
    final out = Uint8List(_bytesPerFrame);
    final output = _ffi.outputBuf;
    for (int i = 0; i < RnnoiseFfi.frameSize; i++) {
      int sample = (output + i).value.round().clamp(-32768, 32767);
      out[i * 2]     = sample & 0xFF;
      out[i * 2 + 1] = (sample >> 8) & 0xFF;
    }
    return out;
  }

  void dispose() {
    _ffi.dispose();
    _buffer.clear();
  }
}
