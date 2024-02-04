import 'package:chess_opening_diary/chess_logic/pieces/piece.dart';

class Tile{
  Tile(this.lightTile, {this.piece});

  final bool lightTile;
  Piece? piece;
  ///Sais if we need to highlight the tile
  bool isSelected = false;
  ///Sais if we need to put a possible move indicator on the tile
  bool isPossibleMove = false;
  ///If true, draws a circle on tile indicating we can capture there
  bool doDrawCaptureCircle = false;

  void setPiece(Piece? piece){
    this.piece = piece;
  }
}