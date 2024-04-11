import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui show Image;

/// Class with a static method to load an image from a string path.
/// Contains a key-image map of loaded images
class ImageTools{
  Map<String, ui.Image> loadedImageMap = {};

  Future<bool> loadImage(String imageAssetPath, int width, int height, String imageKey) async {
    final ByteData data = await rootBundle.load(imageAssetPath);
    final codec = await instantiateImageCodec(
      data.buffer.asUint8List(),
      targetHeight: width,
      targetWidth: height,
    );
    var frame = await codec.getNextFrame();
    loadedImageMap[imageKey] = frame.image;
    return true;
  }

  //Image keys
  static const String lightSquareKey = 'light_square';
  static const String darkSquareKey = 'dark_square';
  static const String darkPawnKey = 'darkPawn';
  static const String lightPawnKey = 'lightPawn';
  static const String lightRookKey = 'lightRook';
  static const String lightKnightKey = 'lightKnight';
  static const String lightBishopKey = 'lightBishop';
  static const String lightKingKey = 'lightKing';
  static const String lightQueenKey = 'lightQueen';
  static const String darkRookKey = 'darkRook';
  static const String darkKnightKey = 'batman';
  static const String darkBishopKey = 'darkBishop';
  static const String darkKingKey = 'darkKing';
  static const String darkQueenKey = 'darkQueen';

  static String getSmallPieceImageKey(String baseImageKey){
    debugPrint('small_$baseImageKey');
    return 'small_$baseImageKey';
  }

  //Image paths
  static const String lightSquarePath = 'assets/images/white_square.png';
  static const String darkSquarePath = 'assets/images/black_square.png';
  static const String darkPawnPath = 'assets/images/dark_pawn.png';
  static const String lightPawnPath = 'assets/images/light_pawn.png';
  static const String lightRookPath = 'assets/images/light_rook.png';
  static const String lightKnightPath = 'assets/images/light_knight.png';
  static const String lightBishopPath = 'assets/images/light_bishop.png';
  static const String lightKingPath = 'assets/images/light_king.png';
  static const String lightQueenPath = 'assets/images/light_queen.png';
  static const String darkRookPath = 'assets/images/dark_rook.png';
  static const String darkKnightPath = 'assets/images/dark_knight.png';
  static const String darkBishopPath = 'assets/images/dark_bishop.png';
  static const String darkKingPath = 'assets/images/dark_king.png';
  static const String darkQueenPath = 'assets/images/dark_queen.png';

}