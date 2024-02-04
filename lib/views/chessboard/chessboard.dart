import 'dart:async';
import 'dart:ui';
import 'package:chess_opening_diary/utils/image_tools.dart';
import 'package:chess_opening_diary/views/chessboard/chessboard_controller_cubit.dart';
import 'package:chess_opening_diary/views/chessboard/tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui show Image;

import '../../chess_logic/pieces/knight.dart';
import '../../chess_logic/pieces/piece.dart';
import '../../utils/global_tools.dart';

class Chessboard extends StatelessWidget {
  Chessboard({super.key, required this.controllerCubit});

  final ChessboardControllerCubit controllerCubit;
  final ImageTools chessImageTools = ImageTools();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadRequiredImages(),
        builder: (context, snap) {
        if(snap.hasData){
          return CustomPaint(
            painter: ChessboardPainter(chessImageTools: chessImageTools, controllerCubit: controllerCubit),
            child: SizedBox.square(
              dimension: controllerCubit.size,
            ),
            // For painting on foreground
            // foregroundPainter: DemoPainter(),
          );
        }else{
          return const CircularProgressIndicator();
        }

      }
    );
  }

  Future<bool> _loadRequiredImages() async{
    int squareSizeAsInt = controllerCubit.size.toInt() ~/ 8;
    await chessImageTools.loadImage(ImageTools.lightSquarePath, squareSizeAsInt, squareSizeAsInt, ImageTools.lightSquareKey);
    await chessImageTools.loadImage(ImageTools.darkSquarePath, squareSizeAsInt, squareSizeAsInt, ImageTools.darkSquareKey);
    await chessImageTools.loadImage(ImageTools.darkPawnPath, squareSizeAsInt, squareSizeAsInt, ImageTools.darkPawnKey);
    await chessImageTools.loadImage(ImageTools.lightPawnPath, squareSizeAsInt, squareSizeAsInt, ImageTools.lightPawnKey);
    await chessImageTools.loadImage(ImageTools.lightRookPath, squareSizeAsInt, squareSizeAsInt, ImageTools.lightRookKey);
    await chessImageTools.loadImage(ImageTools.lightKnightPath, squareSizeAsInt, squareSizeAsInt, ImageTools.lightKnightKey);
    await chessImageTools.loadImage(ImageTools.lightBishopPath, squareSizeAsInt, squareSizeAsInt, ImageTools.lightBishopKey);
    await chessImageTools.loadImage(ImageTools.lightKingPath, squareSizeAsInt, squareSizeAsInt, ImageTools.lightKingKey);
    await chessImageTools.loadImage(ImageTools.lightQueenPath, squareSizeAsInt, squareSizeAsInt, ImageTools.lightQueenKey);
    await chessImageTools.loadImage(ImageTools.darkRookPath, squareSizeAsInt, squareSizeAsInt, ImageTools.darkRookKey);
    await chessImageTools.loadImage(ImageTools.darkKnightPath, squareSizeAsInt, squareSizeAsInt, ImageTools.darkKnightKey);
    await chessImageTools.loadImage(ImageTools.darkBishopPath, squareSizeAsInt, squareSizeAsInt, ImageTools.darkBishopKey);
    await chessImageTools.loadImage(ImageTools.darkKingPath, squareSizeAsInt, squareSizeAsInt, ImageTools.darkKingKey);
    await chessImageTools.loadImage(ImageTools.darkQueenPath, squareSizeAsInt, squareSizeAsInt, ImageTools.darkQueenKey);
    return true;
  }

}

class ChessboardPainter extends CustomPainter{
  final ImageTools chessImageTools;
  final ChessboardControllerCubit controllerCubit;

  ChessboardPainter({required this.chessImageTools, required this.controllerCubit}): super(repaint: controllerCubit.boardPainterUpdateNotifier);


  @override
  void paint(Canvas canvas, Size size) {
    double squareSize = controllerCubit.size/8.0;

    var paint = Paint();

    for(int rowIndex = 0; rowIndex<8; rowIndex++){
      List<Tile> rowData = controllerCubit.tilesData.elementAt(rowIndex);
      for(int colIndex = 0; colIndex<8; colIndex++){
        Tile tileData = rowData.elementAt(colIndex);
        //Draw tile
        double xOffset = colIndex * squareSize;
        double yOffset = rowIndex * squareSize;
        var offset = Offset(xOffset, yOffset);
        if(tileData.lightTile){
          canvas.drawImage(chessImageTools.loadedImageMap[ImageTools.lightSquareKey]!, offset, paint);
        }else{
          canvas.drawImage(chessImageTools.loadedImageMap[ImageTools.darkSquareKey]!, offset, paint);
        }
        Piece? piece = tileData.piece;
        if(piece != null){
          //TODO delete check
          if(chessImageTools.loadedImageMap[piece.imageKey] != null){
            canvas.drawImage(chessImageTools.loadedImageMap[piece.imageKey]!, offset, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}