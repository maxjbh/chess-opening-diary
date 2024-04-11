import 'dart:async';
import 'dart:ui';
import 'package:chess_opening_diary/utils/image_tools.dart';
import 'package:chess_opening_diary/views/chessboard/chessboard_controller_cubit.dart';
import 'package:chess_opening_diary/views/chessboard/tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui' as ui show Image;

import '../../chess_logic/pieces/bishop.dart';
import '../../chess_logic/pieces/king.dart';
import '../../chess_logic/pieces/knight.dart';
import '../../chess_logic/pieces/piece.dart';
import '../../chess_logic/pieces/queen.dart';
import '../../chess_logic/pieces/rook.dart';
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
          return GestureDetector(
              onTapDown: (TapDownDetails pointerEvent) {
                controllerCubit.handleClick(pointerEvent);
              },
              child: BlocBuilder<ChessboardControllerCubit, ChessboardControllerState>(
                bloc: controllerCubit,
                builder: (context, state) {
                  debugPrint("rebuilding!");
                  return CustomPaint(
                              painter: ChessboardPainter(chessImageTools: chessImageTools, controllerCubit: controllerCubit),
                              child: SizedBox.square(
                                dimension: controllerCubit.size,
                              ),
                              // For painting on foreground
                              // foregroundPainter: DemoPainter(),
                            );
                },
            ),
          );
        }else{
          return const CircularProgressIndicator();
        }

      }
    );
  }

  Future<bool> _loadRequiredImages() async{
    int squareSizeAsInt = controllerCubit.size.toInt() ~/ 8;
    int halfSizeAsInt = controllerCubit.size.toInt() ~/ 16;
    debugPrint(squareSizeAsInt.toString());
    debugPrint(halfSizeAsInt.toString());
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
    //Small versions
    await chessImageTools.loadImage(ImageTools.lightRookPath, halfSizeAsInt, halfSizeAsInt, ImageTools.getSmallPieceImageKey(ImageTools.lightRookKey));
    await chessImageTools.loadImage(ImageTools.darkRookPath, halfSizeAsInt, halfSizeAsInt, ImageTools.getSmallPieceImageKey(ImageTools.darkRookKey));
    await chessImageTools.loadImage(ImageTools.lightBishopPath, halfSizeAsInt, halfSizeAsInt, ImageTools.getSmallPieceImageKey(ImageTools.lightBishopKey));
    await chessImageTools.loadImage(ImageTools.darkBishopPath, halfSizeAsInt, halfSizeAsInt, ImageTools.getSmallPieceImageKey(ImageTools.darkBishopKey));
    await chessImageTools.loadImage(ImageTools.lightKnightPath, halfSizeAsInt, halfSizeAsInt, ImageTools.getSmallPieceImageKey(ImageTools.lightKnightKey));
    await chessImageTools.loadImage(ImageTools.darkKnightPath, halfSizeAsInt, halfSizeAsInt, ImageTools.getSmallPieceImageKey(ImageTools.darkKnightKey));
    await chessImageTools.loadImage(ImageTools.lightQueenPath, halfSizeAsInt, halfSizeAsInt, ImageTools.getSmallPieceImageKey(ImageTools.lightQueenKey));
    await chessImageTools.loadImage(ImageTools.darkQueenPath, halfSizeAsInt, halfSizeAsInt, ImageTools.getSmallPieceImageKey(ImageTools.darkQueenKey));
    return true;
  }

}

class ChessboardPainter extends CustomPainter{
  final ImageTools chessImageTools;
  final ChessboardControllerCubit controllerCubit;

  final Paint selectedTilePainter = Paint()
    ..color = Colors.yellow.withOpacity(0.4);

  final Paint checkmateTilePainter = Paint()
    ..color = Colors.red.withOpacity(0.4);

  final Paint captureCirclePainter = Paint()
    ..color = Colors.black54.withOpacity(0.2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 15.0;

  final Paint posibleMovePainter = Paint()
    ..color = Colors.black54.withOpacity(0.2);

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
        double xCenter = xOffset + squareSize/2;
        double yCenter = yOffset + squareSize/2;
        var offset = Offset(xOffset, yOffset);
        if(tileData.lightTile){
          canvas.drawImage(chessImageTools.loadedImageMap[ImageTools.lightSquareKey]!, offset, paint);
        }else{
          canvas.drawImage(chessImageTools.loadedImageMap[ImageTools.darkSquareKey]!, offset, paint);
        }
        if(tileData.isSelected){
          canvas.drawRect(
              Rect.fromLTWH(xOffset, yOffset, squareSize, squareSize),
              selectedTilePainter
          );
        }

        //Draw piece
        Piece? piece = tileData.piece;
        if(piece != null){
          //Draw checkmate indicator before king
          if(controllerCubit.state is CheckmateState && piece is King && piece.lightPiece == controllerCubit.isWhitesTurn){
            canvas.drawRect(
                Rect.fromLTWH(xOffset, yOffset, squareSize, squareSize),
                checkmateTilePainter
            );
          }
          canvas.drawImage(chessImageTools.loadedImageMap[piece.imageKey]!, offset, paint);
        }
        if(tileData.doDrawCaptureCircle){
          canvas.drawCircle(Offset(xCenter, yCenter), squareSize/2 - 6.0, captureCirclePainter);
        }
        if(tileData.isPossibleMove){
          canvas.drawCircle(Offset(xCenter, yCenter), squareSize/4, posibleMovePainter);
        }
        
      }
    }
    //Handle PromotingState
    if(controllerCubit.state is PromotingState){
      PromotingState promotingState = controllerCubit.state as PromotingState;
      _drawPromoteMenu(canvas, promotingState, squareSize);
    }
  }

  void _drawPromoteMenu(Canvas canvas, PromotingState promotingState, double squareSize){
    double xOffset = promotingState.atX * squareSize;
    double yOffset = promotingState.atY * squareSize;
    final Paint imagePainter = Paint();
    //BackgroundPanel
    final Paint backgroundPainter = Paint()
      ..color = Colors.grey.withOpacity(0.1);
    final Paint backgroundRimPainter = Paint()
      ..color = Colors.black54.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawRect(
        Rect.fromLTWH(xOffset, yOffset, squareSize/2.0, squareSize*2),
        backgroundPainter
    );
    canvas.drawRect(
        Rect.fromLTWH(xOffset, yOffset, squareSize/2.0, squareSize*2),
        backgroundRimPainter
    );

    //Draw piece options, order : Queen, Rook, Bishop, Knight
    canvas.drawImage(chessImageTools.loadedImageMap[ImageTools.getSmallPieceImageKey(Queen.getImageKeyForColor(controllerCubit.isWhitesTurn))]!, Offset(xOffset, yOffset), imagePainter);
    canvas.drawImage(chessImageTools.loadedImageMap[ImageTools.getSmallPieceImageKey(Rook.getImageKeyForColor(controllerCubit.isWhitesTurn))]!, Offset(xOffset, yOffset + squareSize/2.0), imagePainter);
    canvas.drawImage(chessImageTools.loadedImageMap[ImageTools.getSmallPieceImageKey(Bishop.getImageKeyForColor(controllerCubit.isWhitesTurn))]!, Offset(xOffset, yOffset + (squareSize/2.0)*2), imagePainter);
    canvas.drawImage(chessImageTools.loadedImageMap[ImageTools.getSmallPieceImageKey(Knight.getImageKeyForColor(controllerCubit.isWhitesTurn))]!, Offset(xOffset, yOffset + (squareSize/2.0)*3), imagePainter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    bool shouldRepaintCopy = controllerCubit.shouldRepaint;
    controllerCubit.setShouldRepaint(false);
    return shouldRepaintCopy;
  }
}